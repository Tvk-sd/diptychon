import SwiftUI

/// The virtual staging set (issue 20) shown in the right auxiliary pane — mutually
/// exclusive with the file Preview. Both file panels stay real directories, so the
/// user sees source, destination, and the staging set at once.
///
/// Backed by a dedicated `PanelModel` whose source is the staging set, so it reuses
/// the same file list as the panels: selection, sort, drag, and the right-click menu
/// all work here too (the operate-on-set slice builds on that selection).
struct StagingPaneView: View {
    let model: PanelModel
    /// Add dropped files to the staging set (drag-to-stage) — owned by the workspace.
    let onDrop: (_ urls: [URL]) -> Void

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Label("Staging", systemImage: "tray.full")
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            switch model.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                if model.visibleItems.isEmpty {
                    ContentUnavailableView {
                        Label("Staging is empty", systemImage: "tray")
                    } description: {
                        Text("Drag files here, or press ⌘⇧S to add the selection.")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // Empty pane is still a drop target, so the first drag stages.
                    .dropDestination(for: URL.self) { urls, _ in onDrop(urls); return true }
                } else {
                    PanelFileList(
                        items: model.visibleItems,
                        selection: $model.selection,
                        sortOrder: $model.sortOrder,
                        onDrop: { urls, _ in onDrop(urls) },
                        onPin: { _ in },
                        renameRequest: nil,
                        onRename: { _, _ in false },
                        accessibilityID: "panel-staging"
                    )
                }
            case .failed(let message):
                ContentUnavailableView("Couldn't load staging", systemImage: "exclamationmark.triangle",
                                       description: Text(message))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { model.load() }
    }
}
