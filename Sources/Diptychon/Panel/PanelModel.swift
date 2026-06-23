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
    private(set) var directory: URL

    /// Loaded rows after filter + sort. **Cached** — recomputed only when the
    /// contents, filter, or sort change, never on every render. (Recomputing on
    /// each access made the `Table` reload mid-click and eat the selection.)
    private(set) var visibleItems: [FileItem] = []

    /// Show hidden (dot) files. Reloads on change.
    var showHidden = false { didSet { reload() } }
    /// Type-ahead filter text; narrows the visible entries.
    var filter = "" { didSet { recomputeVisible() } }
    /// Optional tag filter (by name): when set, show only files carrying it.
    var tagFilter: String? = nil { didSet { recomputeVisible() } }
    /// Column sort order, driven by the `Table` header.
    var sortOrder = [KeyPathComparator(\FileItem.name)] { didSet { recomputeVisible() } }
    /// Current row selection (lifted here so the Commander gesture can act on it).
    var selection = Set<FileItem.ID>()

    private var loadedItems: [FileItem] = []
    private var loadTask: Task<Void, Never>?

    init(directory: URL) {
        self.directory = directory
    }

    var title: String { directory.path }
    /// Can we go up? False at the filesystem root.
    var canGoUp: Bool { directory.path != "/" }

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

    /// Re-list the current directory (after an external change, e.g. a file op).
    func refresh() { reload() }

    /// Enter `item` if it's a directory (files are not activatable yet).
    func navigate(into item: FileItem) {
        guard item.isDirectory else { return }
        directory = item.url
        afterNavigation()
    }

    func navigateUp() {
        guard canGoUp else { return }
        directory = directory.deletingLastPathComponent()
        afterNavigation()
    }

    private func afterNavigation() {
        filter = ""
        tagFilter = nil
        selection = []
        reload()
    }

    /// Re-list the current directory off the main thread. Cancels any in-flight
    /// load so rapid navigation doesn't race.
    private func reload() {
        loadTask?.cancel()
        let source = LocalDirectorySource(directory: directory, includeHidden: showHidden)
        state = .loading
        loadTask = Task {
            do {
                let items = try await source.load()
                if Task.isCancelled { return }
                loadedItems = items
                recomputeVisible()
                state = .loaded
            } catch {
                if Task.isCancelled { return }
                state = .failed(error.localizedDescription)
            }
        }
    }

    /// Apply the current filter + sort to the loaded rows, into the cache.
    private func recomputeVisible() {
        visibleItems = Self.applyFilters(loadedItems, text: filter, tagName: tagFilter)
            .sorted(using: sortOrder)
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
