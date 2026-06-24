import SwiftUI

/// One Panel: a header (path + Up + hidden toggle + filter) above the file list.
/// The model is owned by the parent `WorkspaceView`. Focus is bound to the file
/// list (`Table`) itself via `focus`/`side`, so a single click on a row both
/// activates the Panel and selects the row.
struct PanelView: View {
    let model: PanelModel
    let isActive: Bool
    let onDrop: (_ urls: [URL], _ targetFolder: FileItem?) -> Void
    /// Open the Go to Folder sheet (issue 15) — owned by the workspace.
    var onGoToFolder: () -> Void = {}
    /// Pin a folder to the sidebar (issue 16) — owned by the workspace.
    var onPin: (_ folder: URL) -> Void = { _ in }

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Button { model.navigateUp() } label: {
                    Image(systemName: "chevron.up")
                }
                .disabled(!model.canGoUp)
                .help("Go up (⌘↑)")
                .fixedSize()

                // Clickable path: a menu of ancestor folders (jump up to any) plus
                // Go to Folder… (type an arbitrary path). Issue 15.
                Menu {
                    ForEach(ancestors, id: \.self) { url in
                        Button(url.lastPathComponent.isEmpty ? "/" : url.lastPathComponent) {
                            model.go(to: url)
                        }
                    }
                    Divider()
                    Button("Go to Folder…", action: onGoToFolder)
                } label: {
                    Text(model.title)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .layoutPriority(-1) // give up width first so controls never wrap

                Spacer(minLength: 4)

                // Icon-only toggle for hidden files (keeps the header compact when
                // the preview pane narrows the panel — no wrapping "Hidden" label).
                Button { model.showHidden.toggle() } label: {
                    Image(systemName: model.showHidden ? "eye" : "eye.slash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(model.showHidden ? Color.accentColor : Color.secondary)
                .help(model.showHidden ? "Hide hidden files" : "Show hidden files")
                .fixedSize()

                tagFilterMenu

                TextField("Filter", text: $model.filter)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 70, maxWidth: 160)
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
                    onDrop: onDrop,
                    onPin: onPin
                )
            case .failed(let message):
                if model.accessDenied {
                    VStack(spacing: 10) {
                        Image(systemName: "lock")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary)
                        Text("Couldn't read this folder")
                            .font(.headline)
                        Text("Full Disk Access may be required to read it.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Open Full Disk Access Settings") { FullDiskAccess.openSettings() }
                            .padding(.top, 2)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    /// This panel's ancestor directories, deepest first (current excluded), for
    /// the header path menu.
    private var ancestors: [URL] {
        var result: [URL] = []
        var url = model.directory
        while url.path != "/" {
            let parent = url.deletingLastPathComponent()
            result.append(parent)
            url = parent
        }
        return result
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
