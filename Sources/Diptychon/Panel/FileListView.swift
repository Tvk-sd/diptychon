import SwiftUI

/// ADR 0002 — the file list (the performance-critical heart) lives behind this
/// narrow protocol so the `Table`-based implementation can be swapped for an
/// AppKit `NSTableView` later without touching the rest of the Panel.
///
/// The protocol is intentionally tiny: give it rows, get a view. Everything the
/// Panel needs from "the list" passes through here.
protocol FileListView: View {
    init(items: [FileItem])
}

/// The swap point. The Panel refers to `PanelFileList`, never to a concrete list
/// type. Escape hatch (ADR 0002): if a ~50k-file folder visibly stutters, write
/// an `NSTableViewFileList: FileListView` and change only this line.
typealias PanelFileList = TableFileListView

/// SwiftUI `Table` implementation of the file list. `Table` is column-based and
/// bridged to `NSTableView` internally, so it virtualizes rows for free.
struct TableFileListView: FileListView {
    let items: [FileItem]
    // Selection lives inside the list impl so the `FileListView` protocol stays
    // narrow (just `init(items:)`). Makes the list visibly respond to clicks;
    // it drives nothing else yet (operations arrive in later issues).
    @State private var selection = Set<FileItem.ID>()

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
        Table(items, selection: $selection) {
            TableColumn("Name") { item in
                Label {
                    Text(item.name)
                } icon: {
                    Image(systemName: item.isDirectory ? "folder" : "doc")
                        .foregroundStyle(item.isDirectory ? .blue : .secondary)
                }
            }
            TableColumn("Size") { item in
                // Product default: folders show no size (see PLAN.md).
                Text(item.size.map { Self.sizeFormatter.string(fromByteCount: $0) } ?? "—")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            TableColumn("Date Modified") { item in
                Text(item.modificationDate.map(Self.dateFormatter.string(from:)) ?? "—")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
