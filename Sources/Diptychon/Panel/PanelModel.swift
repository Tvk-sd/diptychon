import SwiftUI
import Observation

/// Per-panel display mode (issue 37): the detailed table, or a compact brief view
/// that lays names + icons out in 1–3 fixed columns (down-then-across). Pane-local —
/// each panel remembers its own mode. The persisted form is `PaneState.briefColumns`
/// (nil = table); kept as an enum here so the column count is never separated from
/// the mode it parameterizes.
enum DisplayMode: Equatable {
    case table
    case brief(columns: Int)
    /// Column browser (issue 91): one folder per column, each showing the contents of
    /// what is selected in the column to its left.
    case columns

    /// Persisted form: nil = table, 1–3 = brief with that many columns. The column
    /// browser has no count of its own — it persists through `persistedName`.
    var briefColumns: Int? {
        switch self {
        case .table, .columns: return nil
        case .brief(let c): return c
        }
    }

    /// Stable string for `PaneState.displayMode` (issue 91). Deliberately not the
    /// enum's synthesized name: this ends up in a persisted blob, so it must survive
    /// a rename of the case.
    var persistedName: String {
        switch self {
        case .table: return "table"
        case .brief: return "brief"
        case .columns: return "columns"
        }
    }

    /// Tolerant restore: nil or an out-of-range count degrades to the table view,
    /// never to a broken pane (same trust principle as `RestorePath`).
    static func from(briefColumns: Int?) -> DisplayMode {
        guard let c = briefColumns, (1...3).contains(c) else { return .table }
        return .brief(columns: c)
    }

    /// Restore from a snapshot (issue 91). **The named mode wins; `briefColumns` only
    /// speaks when there is no name.**
    ///
    /// The order matters and getting it backwards would be silent: a columns pane
    /// persists `briefColumns: nil`, and the old rule maps nil to `.table`, so every
    /// column browser would quietly come back as a table. Pre-91 blobs carry no name
    /// and keep decoding exactly as they did.
    ///
    /// An unknown name also degrades to the table rather than to nothing — a snapshot
    /// written by a newer build must never open a broken pane.
    static func from(persistedName: String?, briefColumns: Int?) -> DisplayMode {
        switch persistedName {
        case "columns": return .columns
        case "brief": return from(briefColumns: briefColumns)
        case "table": return .table
        default: return from(briefColumns: briefColumns)
        }
    }
}

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
            cancelReselect()              // user narrowing ≠ rows deleted (issue 53)
            if filterSearchesSubfolders && searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                scheduleSearch()          // Filter drives a scoped recursive walk
            } else {
                recomputeVisible()        // in-memory narrow (loaded rows or Search results)
            }
        }
    }
    /// Optional tag filter (by name): when set, show only files carrying it.
    var tagFilter: String? = nil { didSet { cancelReselect(); recomputeVisible() } }
    /// Global search query. Non-empty ⇒ the panel shows matches from the whole
    /// **Home** subtree (not just `directory`), so search works from any folder.
    /// Debounced; cancels the prior walk on each change.
    var searchQuery = "" {
        didSet {
            cancelReselect()   // user retargeting ≠ rows deleted (issue 53)
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

    /// The root for global Search — the user's Home dir. Computed once.
    /// `DIPTYCHON_DIR` overrides it so a seeded run (UI tests, demos) searches
    /// the seeded tree, not the real home — same determinism contract as the
    /// pane roots in `URL.startDirectory`.
    static let homeDirectory = ProcessInfo.processInfo.environment["DIPTYCHON_DIR"]
        .map { URL(fileURLWithPath: $0, isDirectory: true) }
        ?? FileManager.default.homeDirectoryForCurrentUser

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
    /// A user selection dismisses the transient "you landed here" target highlight.
    var selection = Set<FileItem.ID>() {
        didSet { if !selection.isEmpty { highlightedTargetURL = nil } }
    }
    /// The file a path-paste jump landed on (see `navigateIfPath`): weakly grey-
    /// highlighted and scrolled into view once its folder finishes loading, then
    /// cleared on the next selection, navigation, or search. `nil` normally.
    var highlightedTargetURL: URL? = nil

    /// One-shot "reselect after trash" intent (issue 53, Finder parity): the
    /// smallest selected visual index + the IDs whose disappearance we await.
    /// Consumed by `recomputeVisible()` once those rows are actually gone — the
    /// trash is async, so a synchronous reselect would land on the dying rows.
    /// Cleared by navigation and by any user-driven filter/search change, so a
    /// stale intent (e.g. a failed trash) can never fire later.
    private var pendingReselect: (index: Int, ids: Set<FileItem.ID>)?

    /// Remember where the selection sits before a trash, so the selection can
    /// land on the nearest surviving row (`min(index, count-1)`) after the rows
    /// vanish. No-op if nothing visible is selected.
    func armReselectAfterTrash() {
        let indices = visibleItems.enumerated()
            .filter { selection.contains($0.element.id) }
            .map(\.offset)
        guard let smallest = indices.min() else { return }
        pendingReselect = (index: smallest, ids: selection)
    }

    private func cancelReselect() { pendingReselect = nil }

    /// Apply an armed reselect once none of the awaited IDs is visible anymore.
    /// Selection is set like a normal user selection (echoes to the table via the
    /// SelectionEchoGuard; `didSet` drops any landing highlight).
    private func consumePendingReselect() {
        guard let pending = pendingReselect else { return }
        guard pending.ids.isDisjoint(with: visibleItems.map(\.id)) else { return }
        pendingReselect = nil
        guard !visibleItems.isEmpty else {
            selection = []
            return
        }
        selection = [visibleItems[min(pending.index, visibleItems.count - 1)].id]
    }
    /// The pane-local display mode (issue 37). Rendering-only: switching modes never
    /// reloads or re-sorts — the brief view reads the same `visibleItems` feed.
    var displayMode: DisplayMode = .table
    /// The column count the last brief view used; toggling back from table restores it.
    private(set) var lastBriefColumns = 2

    /// ⌘1: table ↔ brief. Toggling into brief restores the last column count;
    /// toggling out remembers it.
    func toggleBriefView() {
        switch displayMode {
        case .table, .columns: displayMode = .brief(columns: lastBriefColumns)
        case .brief(let c): lastBriefColumns = c; displayMode = .table
        }
    }

    /// ⌘2: table ↔ column browser (issue 91). Mirrors `toggleBriefView` — pressing it
    /// again returns to the table, so neither view can trap you.
    func toggleColumnView() {
        displayMode = (displayMode == .columns) ? .table : .columns
    }

    /// Set the display mode outright — what the header's three-way switcher calls, so
    /// a click lands on the mode it shows rather than toggling from whatever was
    /// there.
    func setDisplayMode(_ mode: DisplayMode) {
        if case .brief(let c) = mode { lastBriefColumns = min(3, max(1, c)) }
        displayMode = mode
    }

    // MARK: - Column browser (issue 91)

    /// The chain of folders the column browser shows: ancestors, then this pane's
    /// folder. Derived from `directory` every time — see `ColumnChain`.
    var columnChain: [URL] { ColumnChain.columns(for: directory) }

    /// One model per ancestor column, **cached by URL**.
    ///
    /// The chain's identity is derived, but the rows inside a column are not: each
    /// needs listing, sorting and a `DirectoryWatcher`. Rebuilding these per render
    /// would re-list every column and re-arm every watcher on every click — invisible
    /// at four entries, painful at four hundred.
    ///
    /// Not observed: the cache is plumbing, and the columns publish their own changes.
    @ObservationIgnored private var columnModels: [URL: PanelModel] = [:]

    /// The model for one column of the browser.
    ///
    /// The **last** column is this pane itself, so the pane's own selection stays the
    /// one operations act on — copy, move, trash and tag need no knowledge of this
    /// view. Ancestor columns get their own cached models.
    func columnModel(for url: URL) -> PanelModel {
        guard url != directory else { return self }
        if let existing = columnModels[url] { return existing }
        let model = PanelModel(directory: url, makeSource: makeSource)
        model.showHidden = showHidden
        model.sortOrder = sortOrder
        model.load()
        columnModels[url] = model
        return model
    }

    /// Move the browser to `url` — the one mutation the column view performs.
    ///
    /// Uses `relocate`, so a column click records **no** navigation history. Clicking
    /// five levels deep would otherwise leave five back-entries and make ⌘← useless;
    /// the Finder doesn't behave that way either. ⌘← keeps meaning "the previous
    /// *place* I was", not "the previous column".
    ///
    /// Evicts cached columns that are no longer ancestors, so walking around a tree
    /// doesn't accumulate watchers for folders nobody is looking at.
    func openColumn(_ url: URL) {
        relocate(to: url)
        let live = Set(columnChain)
        columnModels = columnModels.filter { live.contains($0.key) }
    }

    /// Palette/menu entry point: switch to the brief view with an explicit column
    /// count (clamped to the 1–3 the issue scopes).
    func setBriefColumns(_ n: Int) {
        lastBriefColumns = min(3, max(1, n))
        displayMode = .brief(columns: lastBriefColumns)
    }

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

    /// Give this panel a selected row if it has none (issue 86).
    ///
    /// Since the Active Panel is now shown by its selection colour rather than a
    /// border, a panel with nothing selected shows no keyboard home. This fills that
    /// in — but **only where it was asked for**: Tab-ing into a panel. A click into
    /// empty space does not, deliberately (Till's call): the selection is also the
    /// target of Return, Space and ⌘⌫, and handing a click a delete candidate the user
    /// never picked would be a nasty surprise. Someone pressing Tab is about to keep
    /// using the keyboard and wants a starting point; someone clicking often just
    /// wanted the panel active.
    ///
    /// A no-op when a selection already exists, so switching back and forth never
    /// moves the user's own selection.
    func selectFirstRowIfEmpty() {
        guard selection.isEmpty, let first = visibleItems.first else { return }
        selection = [first.id]
    }
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

    /// This pane's restorable state — current folder + sort + display mode. Filters/
    /// search are deliberately excluded: panes always reopen unfiltered.
    var paneState: PaneState {
        // The table is the default, so it writes no name at all: a table pane's blob
        // stays byte-identical to what pre-91 builds wrote. Only a pane that is in
        // something other than the table needs to say so.
        PaneState(directoryPath: directory.path, sort: PaneSort(sortOrder),
                  briefColumns: displayMode.briefColumns,
                  displayMode: displayMode == .table ? nil : displayMode.persistedName)
    }

    /// Apply a restored snapshot at launch: set the starting folder + sort + display
    /// mode **without** pushing navigation history (this is where the pane opens, not
    /// a place it navigated to). Call before the first `load()`; the caller resolves
    /// `directory` against what exists on disk (`RestorePath`) so this never opens a
    /// broken pane.
    func restore(directory: URL, sort: PaneSort, briefColumns: Int? = nil,
                 displayMode persistedMode: String? = nil) {
        self.directory = directory
        self.sortOrder = sort.comparators
        self.displayMode = DisplayMode.from(persistedName: persistedMode,
                                            briefColumns: briefColumns)
        if let c = displayMode.briefColumns { lastBriefColumns = c }
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
        go(to: target)             // clears highlightedTargetURL via afterNavigation…
        // …so set it *after*: a file jump marks the file (a dir jump marks nothing —
        // we're now inside it). The list highlights + scrolls to it once loaded.
        highlightedTargetURL = isDir.boolValue ? nil : url
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
        cancelReselect()   // a pending post-trash reselect belongs to the old folder
        searchQuery = ""   // leaving the folder exits search
        filter = ""
        tagFilter = nil
        selection = []
        highlightedTargetURL = nil   // a fresh navigation drops any landing marker

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
        consumePendingReselect()
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
