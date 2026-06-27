import SwiftUI
import Observation

/// UI-side state for one Panel. `@MainActor` because everything it publishes is
/// read by SwiftUI; the *loading* work itself is delegated to a `PanelSource`,
/// which runs off the main thread.
///
/// For the MVP a Panel navigates a local directory tree, so the model owns a
/// `directory: URL` and builds a `LocalDirectorySource` per load. (ADR 0003 still
/// mediates loading; navigation is local-path here and generalizes when non-local
/// sources arrive.)
@MainActor
@Observable
final class PanelModel {
    enum LoadState {
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: LoadState = .loading
    /// True when the last load failed specifically on a permission error — drives
    /// the inline "Open Full Disk Access Settings" guidance (issue 10).
    private(set) var accessDenied = false
    private(set) var directory: URL

    /// Loaded rows after filter + sort. **Cached** — recomputed only when the
    /// contents, filter, or sort change, never on every render. (Recomputing on
    /// each access made the `Table` reload mid-click and eat the selection.)
    private(set) var visibleItems: [FileItem] = []

    /// Show hidden (dot) files. Reloads on change; re-runs an active search so its
    /// results respect the new visibility.
    var showHidden = false { didSet { reload(); if isSearching { scheduleSearch() } } }
    /// Type-ahead filter text; narrows the visible entries.
    var filter = "" { didSet { recomputeVisible() } }
    /// Optional tag filter (by name): when set, show only files carrying it.
    var tagFilter: String? = nil { didSet { recomputeVisible() } }
    /// Recursive search query (issue 21 slice 3). Non-empty ⇒ the panel shows
    /// matches from the subtree under `directory` instead of its direct contents.
    /// Debounced; cancels the prior walk on each change.
    var searchQuery = "" { didSet { scheduleSearch() } }
    /// Matches from the last/in-flight search — the base set for `visibleItems`
    /// while `isSearching`.
    private(set) var searchResults: [FileItem] = []
    /// Whether the panel is currently showing search results rather than `directory`.
    var isSearching: Bool { !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty }
    /// True while a search walk is in flight — drives the "Searching…" state so the
    /// panel never shows the stale directory listing under a search header.
    private(set) var isSearchRunning = false
    /// Column sort order, driven by the `Table` header.
    var sortOrder = [KeyPathComparator(\FileItem.name)] { didSet { recomputeVisible() } }
    /// Current row selection (lifted here so the Commander gesture can act on it).
    var selection = Set<FileItem.ID>()
    /// Bumped to ask the list to begin an inline rename on the selected row (issue
    /// 11). The `NSTableView` watches this token and calls `editColumn`.
    var inlineRenameRequest: UUID?

    /// Ask the file list to start editing the single selected row's name in place.
    func requestInlineRename() { inlineRenameRequest = UUID() }

    /// Per-panel browser-style navigation history (issue 21 slice 2). Every dir
    /// change pushes the prior directory onto `backStack` and clears `forwardStack`;
    /// goBack/goForward shuttle between them without recording new history.
    private var backStack: [URL] = []
    private var forwardStack: [URL] = []

    private var loadedItems: [FileItem] = []
    private var loadTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    /// Live watch on `directory`; refreshes the Panel on external changes (AC3).
    private var watcher: DirectoryWatcher?
    private var watchedDirectory: URL?

    /// Builds the `PanelSource` for a directory + hidden-files state. Injected so
    /// tests can supply a fake source (no filesystem); defaults to the real local
    /// directory source (ADR 0003). Rebuilt per load since directory/showHidden change.
    private let makeSource: (URL, Bool) -> PanelSource

    init(directory: URL,
         makeSource: @escaping (URL, Bool) -> PanelSource =
             { LocalDirectorySource(directory: $0, includeHidden: $1) }) {
        self.directory = directory
        self.makeSource = makeSource
    }

    var title: String { directory.path }
    /// Can we go up? False at the filesystem root.
    var canGoUp: Bool { directory.path != "/" }
    /// Back/forward availability (issue 21 slice 2).
    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }

    /// URLs of the currently selected rows (source set for the Commander gesture).
    var selectionURLs: [URL] { Array(selection) }

    /// The currently selected rows as items, in display order.
    var selectedItems: [FileItem] { visibleItems.filter { selection.contains($0.id) } }

    /// Distinct tags present across the loaded rows (for the header's filter menu),
    /// first-seen order. Includes custom tags, not just the built-in colors.
    var availableTags: [FinderTag] {
        var seen = Set<String>()
        var result: [FinderTag] = []
        for item in loadedItems {
            for tag in item.tags where seen.insert(tag.name).inserted {
                result.append(tag)
            }
        }
        return result
    }

    func load() { reload() }

    /// Re-list the current directory (after a file op or an external change).
    /// No loading flash — the rows are already on screen.
    func refresh() { reload(showLoading: false) }

    /// Enter `item` if it's a directory (files are not activatable yet).
    func navigate(into item: FileItem) {
        guard item.isDirectory else { return }
        pushHistoryAndGo(to: item.url)
    }

    /// Jump directly to a directory (path bar / Go to Folder / breadcrumb).
    func go(to url: URL) {
        pushHistoryAndGo(to: url)
    }

    func navigateUp() {
        guard canGoUp else { return }
        pushHistoryAndGo(to: directory.deletingLastPathComponent())
    }

    /// Go to `url`, recording the current directory in history (browser-style):
    /// push the prior dir onto back, drop any forward trail. No-op if unchanged.
    private func pushHistoryAndGo(to url: URL) {
        guard url != directory else { return }
        backStack.append(directory)
        forwardStack.removeAll()
        directory = url
        afterNavigation()
    }

    /// Step back to the previous directory (forward becomes available).
    func goBack() {
        guard let previous = backStack.popLast() else { return }
        forwardStack.append(directory)
        directory = previous
        afterNavigation()
    }

    /// Step forward again after going back.
    func goForward() {
        guard let next = forwardStack.popLast() else { return }
        backStack.append(directory)
        directory = next
        afterNavigation()
    }

    private func afterNavigation() {
        searchQuery = ""   // leaving the folder exits search
        filter = ""
        tagFilter = nil
        selection = []
        reload()
    }

    /// Debounced recursive search of the current subtree. Cancels any in-flight
    /// walk first (so each keystroke supersedes the last); an empty query clears
    /// results and returns to the normal directory listing.
    private func scheduleSearch() {
        searchTask?.cancel()
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            isSearchRunning = false
            searchResults = []
            recomputeVisible()
            return
        }
        // Switch the panel into search mode *now* so the stale directory listing is
        // dropped immediately (the header already reads `isSearching` live).
        isSearchRunning = true
        recomputeVisible()
        let root = directory
        let includeHidden = showHidden
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))   // debounce
            if Task.isCancelled { return }
            let results = await RecursiveSearch.run(query: query, in: root, includeHidden: includeHidden)
            if Task.isCancelled { return }
            self?.searchResults = results
            self?.isSearchRunning = false
            self?.recomputeVisible()
        }
    }

    /// Re-list the current directory off the main thread. Cancels any in-flight
    /// load so rapid navigation doesn't race. `showLoading` is false for refreshes
    /// (file ops / live watch) so the on-screen rows don't flash to a spinner.
    private func reload(showLoading: Bool = true) {
        loadTask?.cancel()
        startWatching()
        let source = makeSource(directory, showHidden)
        if showLoading { state = .loading }
        loadTask = Task {
            do {
                let items = try await source.load()
                if Task.isCancelled { return }
                loadedItems = items
                // A refresh while searching (e.g. after trashing a result) must drop
                // results whose file is now gone — the panel shows searchResults, not
                // loadedItems, so reloading the directory alone wouldn't remove them.
                if isSearching {
                    let fm = FileManager.default
                    searchResults = searchResults.filter { fm.fileExists(atPath: $0.url.path) }
                }
                recomputeVisible()
                accessDenied = false
                state = .loaded
            } catch {
                if Task.isCancelled { return }
                accessDenied = (error as NSError).code == NSFileReadNoPermissionError
                state = .failed(error.localizedDescription)
            }
        }
    }

    /// (Re)watch the current directory for external changes. Recreated only when
    /// the directory changes; the callback refreshes the listing in place (AC3).
    private func startWatching() {
        guard watchedDirectory != directory else { return }
        watchedDirectory = directory
        watcher = DirectoryWatcher(url: directory) { [weak self] in self?.refresh() }
    }

    /// Apply the current filter + sort to the base rows, into the cache. The base
    /// set is the search results while searching, otherwise the loaded directory.
    private func recomputeVisible() {
        visibleItems = Self.compileVisible(
            loaded: loadedItems, searchResults: searchResults, isSearching: isSearching,
            filter: filter, tagName: tagFilter, sort: sortOrder)
    }

    /// Pure base→filter→sort pipeline that produces the rows a Panel shows. The base
    /// set is the search results while searching, otherwise the loaded directory.
    /// Pulled out whole so it's unit-testable without an async load or live model.
    static func compileVisible(loaded: [FileItem], searchResults: [FileItem], isSearching: Bool,
                               filter: String, tagName: String?,
                               sort: [KeyPathComparator<FileItem>]) -> [FileItem] {
        let base = isSearching ? searchResults : loaded
        return applyFilters(base, text: filter, tagName: tagName).sorted(using: sort)
    }

    /// Pure filter step (type-ahead text + optional tag), factored out so it's
    /// unit-testable without spinning up an async directory load.
    static func applyFilters(_ items: [FileItem], text: String, tagName: String?) -> [FileItem] {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        var result = items
        if !trimmed.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        }
        if let tagName {
            result = result.filter { $0.tags.contains { $0.name == tagName } }
        }
        return result
    }
}
