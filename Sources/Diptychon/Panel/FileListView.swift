import SwiftUI

/// ADR 0002 — the file list (the performance-critical heart) lives behind this
/// protocol so the `Table`-based implementation can be swapped for an AppKit
/// `NSTableView` later without touching the rest of the Panel.
///
/// It carries exactly what the Panel needs: the rows, plus bindings for selection
/// and sort order. Opening a row (double-click) is handled at the workspace level
/// via the mouse monitor, so the list stays free of tap gestures that would
/// otherwise swallow single-click selection.
protocol FileListView: View {
    init(
        items: [FileItem],
        selection: Binding<Set<FileItem.ID>>,
        sortOrder: Binding<[KeyPathComparator<FileItem>]>,
        onDrop: @escaping (_ urls: [URL], _ targetFolder: FileItem?) -> Void,
        onPin: @escaping (_ folder: URL) -> Void,
        onAddToStaging: @escaping (_ urls: [URL]) -> Void,
        renameRequest: UUID?,
        onRename: @escaping (_ item: FileItem, _ newName: String) -> Bool,
        accessibilityID: String
    )
}

/// The swap point. The Panel refers to `PanelFileList`, never to a concrete list
/// type. Per ADR 0002 we took the AppKit escape hatch: SwiftUI `Table` couldn't
/// do row-drag + reliable click-selection together, so the list is backed by
/// `NSTableViewFileList`. `TableFileListView` (SwiftUI) is kept as the reference
/// implementation behind the same protocol.
typealias PanelFileList = NSTableViewFileList

/// SwiftUI `Table` implementation of the file list. `Table` is column-based and
/// bridged to `NSTableView` internally, so it virtualizes rows for free.
struct TableFileListView: FileListView {
    let items: [FileItem]
    @Binding var selection: Set<FileItem.ID>
    @Binding var sortOrder: [KeyPathComparator<FileItem>]
    let onDrop: (_ urls: [URL], _ targetFolder: FileItem?) -> Void
    let onPin: (_ folder: URL) -> Void
    let onAddToStaging: (_ urls: [URL]) -> Void
    let renameRequest: UUID?
    let onRename: (_ item: FileItem, _ newName: String) -> Bool
    let accessibilityID: String

    init(
        items: [FileItem],
        selection: Binding<Set<FileItem.ID>>,
        sortOrder: Binding<[KeyPathComparator<FileItem>]>,
        onDrop: @escaping (_ urls: [URL], _ targetFolder: FileItem?) -> Void,
        onPin: @escaping (_ folder: URL) -> Void,
        onAddToStaging: @escaping (_ urls: [URL]) -> Void = { _ in },
        renameRequest: UUID?,
        onRename: @escaping (_ item: FileItem, _ newName: String) -> Bool,
        accessibilityID: String = ""
    ) {
        self.items = items
        self._selection = selection
        self._sortOrder = sortOrder
        self.onDrop = onDrop
        self.onPin = onPin
        self.onAddToStaging = onAddToStaging
        self.renameRequest = renameRequest
        self.onRename = onRename
        self.accessibilityID = accessibilityID
    }

    private static let sizeFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        Table(items, selection: $selection, sortOrder: $sortOrder) {
            // `value:` makes each column header sortable; the trailing closure
            // renders the cell.
            TableColumn("Name", value: \.name) { item in
                Label {
                    Text(item.name)
                } icon: {
                    Image(systemName: item.isDirectory ? "folder" : "doc")
                        .foregroundStyle(item.isDirectory ? .blue : .secondary)
                }
                // Drag this row out (to Finder, the other Panel, or a subfolder).
                // `onDrag` (not `draggable`) so a plain click still selects the row.
                .onDrag { NSItemProvider(object: item.url as NSURL) }
                // Folder rows accept drops (drop INTO the folder) + highlight.
                .modifier(FolderDropModifier(item: item, onDrop: onDrop))
            }
            TableColumn("Size", value: \.sizeForSort) { item in
                // Product default: folders show no size (see PLAN.md).
                Text(item.size.map { Self.sizeFormatter.string(fromByteCount: $0) } ?? "—")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            TableColumn("Date Modified", value: \.dateForSort) { item in
                Text(item.modificationDate.map(Self.dateFormatter.string(from:)) ?? "—")
                    .foregroundStyle(.secondary)
            }
        }
        // Drops on the list background target the Panel's current directory.
        .dropDestination(for: URL.self) { urls, _ in
            onDrop(urls, nil)
            return true
        }
        .accessibilityIdentifier(accessibilityID)
    }
}

/// Makes a folder row a drop target (drops land inside that folder), highlighting
/// it while a drag hovers. Non-folder rows are inert.
private struct FolderDropModifier: ViewModifier {
    let item: FileItem
    let onDrop: (_ urls: [URL], _ targetFolder: FileItem?) -> Void
    @State private var targeted = false

    func body(content: Content) -> some View {
        if item.isDirectory {
            content
                .background {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor.opacity(targeted ? 0.25 : 0))
                }
                .dropDestination(for: URL.self) { urls, _ in
                    onDrop(urls, item)
                    return true
                } isTargeted: { targeted = $0 }
        } else {
            content
        }
    }
}
