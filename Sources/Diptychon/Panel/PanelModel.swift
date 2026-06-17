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
        case loaded([FileItem])
        case failed(String)
    }

    private(set) var state: LoadState = .loading
    private(set) var directory: URL

    /// Show hidden (dot) files. Reloads on change.
    var showHidden = false { didSet { reload() } }
    /// Type-ahead filter text; narrows the visible entries.
    var filter = ""
    /// Column sort order, driven by the `Table` header.
    var sortOrder = [KeyPathComparator(\FileItem.name)]
    /// Current row selection (lifted here so Return/activate can act on it).
    var selection = Set<FileItem.ID>()

    private var loadTask: Task<Void, Never>?

    init(directory: URL) {
        self.directory = directory
    }

    var title: String { directory.path }
    /// Can we go up? False at the filesystem root.
    var canGoUp: Bool { directory.path != "/" }

    /// All loaded rows after applying the type-ahead filter and the sort order.
    var visibleItems: [FileItem] {
        guard case .loaded(let items) = state else { return [] }
        let trimmed = filter.trimmingCharacters(in: .whitespaces)
        let filtered = trimmed.isEmpty
            ? items
            : items.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        return filtered.sorted(using: sortOrder)
    }

    func load() {
        reload()
    }

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
                state = .loaded(items)
            } catch {
                if Task.isCancelled { return }
                state = .failed(error.localizedDescription)
            }
        }
    }
}
