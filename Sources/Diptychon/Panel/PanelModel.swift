import SwiftUI
import Observation

/// UI-side state for one Panel. `@MainActor` because everything it publishes is
/// read by SwiftUI; the *loading* work itself is delegated to the `PanelSource`,
/// which runs off the main thread.
@MainActor
@Observable
final class PanelModel {
    enum LoadState {
        case idle
        case loading
        case loaded([FileItem])
        case failed(String)
    }

    private(set) var state: LoadState = .idle
    let source: PanelSource

    init(source: PanelSource) {
        self.source = source
    }

    var title: String { source.title }

    func load() async {
        state = .loading
        do {
            let items = try await source.load()
            state = .loaded(items)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
