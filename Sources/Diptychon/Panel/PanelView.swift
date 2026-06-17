import SwiftUI

/// One Panel: a header (path + Up + hidden toggle + filter) above the file list.
/// The model is owned by the parent `WorkspaceView`. Focus is bound to the file
/// list (`Table`) itself via `focus`/`side`, so a single click on a row both
/// activates the Panel and selects the row.
struct PanelView: View {
    let model: PanelModel
    let isActive: Bool

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Button { model.navigateUp() } label: {
                    Image(systemName: "chevron.up")
                }
                .disabled(!model.canGoUp)
                .help("Go up (⌘↑)")

                Text(model.title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.head)

                Spacer()

                Toggle("Hidden", isOn: $model.showHidden)
                    .toggleStyle(.checkbox)

                TextField("Filter", text: $model.filter)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Content
            switch model.state {
            case .loading:
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                PanelFileList(
                    items: model.visibleItems,
                    selection: $model.selection,
                    sortOrder: $model.sortOrder,
                    onActivate: { model.navigate(into: $0) }
                )
            case .failed(let message):
                ContentUnavailableView(
                    "Couldn't read folder",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .task { model.load() }
        // Active Panel is visually distinct.
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.accentColor, lineWidth: isActive ? 2 : 0)
        }
    }
}
