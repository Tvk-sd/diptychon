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
    /// Whether the Filter recurses into subfolders (a `directory` walk) or just
    /// narrows the loaded rows in-memory. Only true for panes backed by a real
    /// local directory — a virtual source (e.g. Staging, ADR 0003) has no subtree
    /// to walk, and walking its nominal `directory` would show unrelated real
    /// files. Set by `WorkspaceModel` on the two directory panes.
    var filterSearchesSubfolders = false
    /// Filter text. When the pane recurses (`filterSearchesSubfolders`) and no
    /// global Search is active, it drives a scoped recursive walk of the current
    /// folder; otherwise it just narrows the loaded rows (or Search results)
    /// in-memory.
    var filter = "" {
        didSet {
            if filterSearchesSubfolders && searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                scheduleSearch()          // Filter drives a scoped recursive walk
            } else {
                recomputeVisible()        // in-memory narrow (loaded rows or Search results)
            }
        }
    }
    /// Optional tag filter (by name): when set, show only files carrying it.
    var tagFilter: String? = nil { didSet { recomputeVisible() } }
    /// Global search query. Non-empty ⇒ the panel shows matches from the whole
    /// **Home** subtree (not just `directory`), so search works from any folder.
    /// Debounced; cancels the prior walk on each change.
    var searchQuery = "" {
        didSet {
            // A pasted/typed absolute or `~` path jumps straight there — done live,
            // not on Enter, because the app's key monitor swallows Return before
            // SwiftUI's onSubmit. Only fires when the path actually resolves, so a
            // normal query (never starts with `/` or `~`) falls through to search.
            if navigateIfPath(searchQuery) { return }
            scheduleSearch()
        }
    }
    /// Matches from the last/in-flight walk — the base set for `visibleItems`
    /// while `isSearching`.
    private(set) var searchResults: [FileItem] = []

    /// The user's Home dir — the root for global Search. Computed once.
    static let homeDirectory = FileManager.default.homeDirectoryForCurrentUser

    /// Which subtree the recursive walk covers, and with what query, given both
    /// input fields. Global **Search** wins when present (root = `home`); otherwise,
    /// only when the pane recurses (`filterRecurses`), the **Filter** drives a walk
    /// scoped to the current `directory`. `nil` ⇒ no walk, so the panel shows its
    /// plain directory listing (the Filter, if any, narrows it in-memory).
    static func searchDriver(searchQuery: String, filter: String,
                             directory: URL, home: URL,
                             filterRecurses: Bool) -> (query: String, root: URL)? {
        let sq = searchQuery.trimmingCharacters(in: .whitespaces)
        if !sq.isEmpty { return (sq, home) }
        guard filterRecurses else { return nil }
        let fq = filter.trimmingCharacters(in: .whitespaces)
        if !fq.isEmpty { return (fq, directory) }
        return nil
    }

    private func searchDriver() -> (query: String, root: URL)? {
        Self.searchDriver(searchQuery: searchQuery, filter: filter, directory: directory,
                          home: Self.homeDirectory, filterRecurses: filterSearchesSubfolders)
    }

    /// Whether the panel is showing walk results (global Search, or a recursive
    /// Filter) rather than its plain `directory` listing.
    var isSearching: Bool { searchDriver() != nil }
    /// The query text to show in the "no results" state — whichever field is driving.
    var searchQueryDisplay: String { searchDriver()?.query ?? "" }
    /// True while a search walk is in flight — drives the "Searching…" state so the
    /// panel never shows the stale directory listing under a search header.
    private(set) var isSearchRunning = false
    /// Column sort order, driven by the `Table` header. Default: most recently
    /// modified first (newest at top), the standard file-manager view (issue 29).
    var sortOrder = [KeyPathComparator(\FileItem.dateForSort, order: .reverse)] { didSet { recomputeVisible() } }
    /// Current row selection (lifted here so the Commander gesture can act on it).
    var selection = Set<FileItem.ID>()
    /// Bumped to ask the list to begin an inline rename on the selected row (issue
    /// 11). The `NSTableView` watches this token and calls `editColumn`.
    var inlineRenameRequest: UUID?

    /// Ask the file list to start editing the single selected row's name in place.
    func requestInlineRename() { inlineRenameRequest = UUID() }

    // MARK: - Selection commands (issue 28)
    // Mutate `selection` directly; the list echoes it to the `NSTableView` via the
    // SelectionEchoGuard, so the cursor never moves (Marta-style: selection is not
    // tied to the cursor).

    func selectAll() { selection = Set(visibleItems.map(\.id)) }
    func selectNone() { selection = [] }
    func invertSelection() {
        selection = Set(visibleItems.map(\.id)).subtracting(selection)
    }

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
        FinderTag.distinctByName(in: loadedItems.map(\.tags))
    }

    func load() { reload() }

    // MARK: - State persistence (issue 41)

    /// This pane's restorable state — current folder + sort. Filters/search are
    /// deliberately excluded: panes always reopen unfiltered.
    var paneState: PaneState {
        PaneState(directoryPath: directory.path, sort: PaneSort(sortOrder))
    }

    /// Apply a restored snapshot at launch: set the starting folder + sort **without**
    /// pushing navigation history (this is where the pane opens, not a place it
    /// navigated to). Call before the first `load()`; the caller resolves `directory`
    /// against what exists on disk (`RestorePath`) so this never opens a broken pane.
    func restore(directory: URL, sort: PaneSort) {
        self.directory = directory
        self.sortOrder = sort.comparators
    }

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

    /// If `raw` is an absolute (`/…`) or tilde (`~/…`) path to something that
    /// exists, navigate there (a file lands in its containing folder) and clear
    /// the search. Lets the user paste a full path into Search and jump to it.
    /// Returns whether it was handled, so the caller can fall through to searching.
    @discardableResult
    func navigateIfPath(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("/") || trimmed.hasPrefix("~") else { return false }
        let expanded = (trimmed as NSString).expandingTildeInPath
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: expanded, isDirectory: &isDir) else { return false }
        let url = URL(fileURLWithPath: expanded)
        let target = isDir.boolValue ? url : url.deletingLastPathComponent()
        searchQuery = ""            // leave search mode; go(to:) also clears filters
        go(to: target)
        return true
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

    /// Move the pane to `url` **without** recording history — used when the current
    /// folder vanishes under it (drive unmounted, issue 41) or comes back on remount.
    /// Unlike `go`, there is no "back" to a folder that no longer exists.
    func relocate(to url: URL) {
        guard url != directory else { return }
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
        // Root + query depend on which field is active: global Search (Home) wins,
        // else a recursing Filter scopes to the current folder. Nil ⇒ nothing to walk.
        guard let driver = searchDriver() else {
            isSearchRunning = false
            searchResults = []
            recomputeVisible()
            return
        }
        // Switch the panel into search mode *now* so the stale directory listing is
        // dropped immediately (the header already reads `isSearching` live).
        isSearchRunning = true
        recomputeVisible()
        let includeHidden = showHidden
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))   // debounce
            if Task.isCancelled { return }
            let results = await RecursiveSearch.run(query: driver.query, in: driver.root, includeHidden: includeHidden)
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
                let loadStart = DispatchTime.now()
                let items = try await source.load()
                if Task.isCancelled { return }
                Perf.markListLoad(items: items.count, since: loadStart)
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
                // First panel to reach `.loaded` reports the cold-launch baseline
                // (self-guards to fire once per launch; no-op thereafter).
                Perf.markFirstPanelInteractive()
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
        let filtered = applyFilters(base, text: filter, tagName: tagName)
        // In search mode keep the relevance order the walk produced (best matches
        // first); only the plain directory listing obeys the column sort.
        return isSearching ? filtered : filtered.sorted(using: sort)
    }

    /// Pure filter step (type-ahead text + optional tag), factored out so it's
    /// unit-testable without spinning up an async directory load.
    static func applyFilters(_ items: [FileItem], text: String, tagName: String?) -> [FileItem] {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        var result = items
        if !trimmed.isEmpty {
            // Fuzzy (normalized subsequence), same matcher as recursive Search so
            // both fields behave identically. Needle normalized once, not per row.
            let needle = FuzzyMatch.normalize(trimmed)
            result = result.filter { FuzzyMatch.matches(needle: needle, candidate: $0.name) }
        }
        if let tagName {
            result = result.filter { $0.tags.contains { $0.name == tagName } }
        }
        return result
    }
}
