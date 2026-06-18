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
        sortOrder: Binding<[KeyPathComparator<FileItem>]>
    )
}

/// The swap point. The Panel refers to `PanelFileList`, never to a concrete list
/// type. Escape hatch (ADR 0002): if a ~50k-file folder visibly stutters, write
/// an `NSTableViewFileList: FileListView` and change only this line.
typealias PanelFileList = TableFileListView

/// SwiftUI `Table` implementation of the file list. `Table` is column-based and
/// bridged to `NSTableView` internally, so it virtualizes rows for free.
struct TableFileListView: FileListView {
    let items: [FileItem]
    @Binding var selection: Set<FileItem.ID>
    @Binding var sortOrder: [KeyPathComparator<FileItem>]

    init(
        items: [FileItem],
        selection: Binding<Set<FileItem.ID>>,
        sortOrder: Binding<[KeyPathComparator<FileItem>]>
    ) {
        self.items = items
        self._selection = selection
        self._sortOrder = sortOrder
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
    }
}
