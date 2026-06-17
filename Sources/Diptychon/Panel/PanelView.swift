import SwiftUI

/// One Panel: a header (path + Up + hidden toggle + filter) above the file list.
/// Renders whatever its `PanelModel` provides via the `PanelFileList` swap point.
/// The model is owned by the parent `WorkspaceView`; `isActive` marks this as the
/// Active Panel (see `/CONTEXT.md`).
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
                // The UI stays live here while the directory loads off-thread.
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
        // Keyboard nav only acts on the Active Panel (keyboard-first, PRD).
        .onKeyPress(.return) {
            guard isActive else { return .ignored }
            activateSelection()
            return .handled
        }
        .onKeyPress { press in
            guard isActive, press.key == .upArrow, press.modifiers.contains(.command)
            else { return .ignored }
            model.navigateUp()
            return .handled
        }
    }

    /// Open the selected row when exactly one is selected (Return key).
    private func activateSelection() {
        guard model.selection.count == 1,
              let id = model.selection.first,
              let item = model.visibleItems.first(where: { $0.id == id })
        else { return }
        model.navigate(into: item)
    }
}
