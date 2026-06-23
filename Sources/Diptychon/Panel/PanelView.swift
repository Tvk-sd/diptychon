import SwiftUI

/// One Panel: a header (path + Up + hidden toggle + filter) above the file list.
/// The model is owned by the parent `WorkspaceView`. Focus is bound to the file
/// list (`Table`) itself via `focus`/`side`, so a single click on a row both
/// activates the Panel and selects the row.
struct PanelView: View {
    let model: PanelModel
    let isActive: Bool
    let onDrop: (_ urls: [URL], _ targetFolder: FileItem?) -> Void

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

                tagFilterMenu

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
                    onDrop: onDrop
                )
            case .failed(let message):
                if model.accessDenied {
                    ContentUnavailableView {
                        Label("Couldn't read this folder", systemImage: "lock")
                    } description: {
                        Text("Full Disk Access may be required to read it.")
                    } actions: {
                        Button("Open Full Disk Access Settings") { FullDiskAccess.openSettings() }
                    }
                } else {
                    ContentUnavailableView(
                        "Couldn't read folder",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                }
            }
        }
        .task { model.load() }
        // Active Panel is visually distinct.
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.accentColor, lineWidth: isActive ? 2 : 0)
        }
    }

    /// Header control to filter the Panel to a single tag (AC4). Lists the tags
    /// actually present in the folder; selecting one again clears the filter.
    @ViewBuilder
    private var tagFilterMenu: some View {
        @Bindable var model = model
        Menu {
            Button {
                model.tagFilter = nil
            } label: {
                Label("All Tags", systemImage: model.tagFilter == nil ? "checkmark" : "tag")
            }
            if !model.availableTags.isEmpty {
                Divider()
                ForEach(model.availableTags, id: \.name) { tag in
                    Button {
                        model.tagFilter = (model.tagFilter == tag.name) ? nil : tag.name
                    } label: {
                        Label {
                            Text(tag.name)
                        } icon: {
                            Image(systemName: model.tagFilter == tag.name ? "checkmark.circle.fill" : "circle.fill")
                                .foregroundStyle(Color(nsColor: tag.color.nsColor ?? .secondaryLabelColor))
                        }
                    }
                }
            }
        } label: {
            Image(systemName: model.tagFilter == nil ? "tag" : "tag.fill")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Filter by tag")
        .disabled(model.availableTags.isEmpty && model.tagFilter == nil)
    }
}
