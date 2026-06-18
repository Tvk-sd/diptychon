import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// AppKit `NSTableView` implementation of the file list (ADR 0002 escape hatch).
/// Chosen over SwiftUI `Table` because AppKit handles selection, double-click,
/// drag, and drop natively without the gesture conflicts that plague a SwiftUI
/// `Table` (a row drag modifier there swallows click-selection). Same
/// `FileListView` protocol, so the rest of the app is unchanged.
struct NSTableViewFileList: NSViewRepresentable, FileListView {
    let items: [FileItem]
    @Binding var selection: Set<FileItem.ID>
    @Binding var sortOrder: [KeyPathComparator<FileItem>]
    let onDrop: (_ urls: [URL], _ targetFolder: FileItem?) -> Void

    init(
        items: [FileItem],
        selection: Binding<Set<FileItem.ID>>,
        sortOrder: Binding<[KeyPathComparator<FileItem>]>,
        onDrop: @escaping (_ urls: [URL], _ targetFolder: FileItem?) -> Void
    ) {
        self.items = items
        self._selection = selection
        self._sortOrder = sortOrder
        self.onDrop = onDrop
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let table = NSTableView()
        table.style = .inset
        table.usesAlternatingRowBackgroundColors = true
        table.allowsMultipleSelection = true
        table.dataSource = context.coordinator
        table.delegate = context.coordinator
        table.target = context.coordinator
        table.rowHeight = 24

        addColumn(table, id: Column.name, title: "Name", width: 280, sortKey: "name")
        addColumn(table, id: Column.size, title: "Size", width: 90, sortKey: "size")
        addColumn(table, id: Column.date, title: "Date Modified", width: 160, sortKey: "date")

        // Drag out (to Finder / other Panel) + accept drops (from Finder / Panels).
        table.setDraggingSourceOperationMask(.copy, forLocal: true)
        table.setDraggingSourceOperationMask(.copy, forLocal: false)
        table.registerForDraggedTypes([.fileURL])

        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        context.coordinator.table = table
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let table = scroll.documentView as? NSTableView else { return }
        context.coordinator.syncContents(table)
        context.coordinator.syncSelection(table)
    }

    private func addColumn(_ table: NSTableView, id: String, title: String, width: CGFloat, sortKey: String) {
        let col = NSTableColumn(identifier: .init(id))
        col.title = title
        col.width = width
        col.sortDescriptorPrototype = NSSortDescriptor(key: sortKey, ascending: true)
        table.addTableColumn(col)
    }

    enum Column { static let name = "name", size = "size", date = "date" }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var parent: NSTableViewFileList
        weak var table: NSTableView?
        private var displayedIDs: [FileItem.ID] = []
        private var isSyncingSelection = false

        private static let sizeFormatter: ByteCountFormatter = {
            let f = ByteCountFormatter(); f.countStyle = .file; return f
        }()
        private static let dateFormatter: DateFormatter = {
            let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
        }()

        init(_ parent: NSTableViewFileList) { self.parent = parent }

        /// Reload only when the rows actually changed (avoids reload-mid-click).
        func syncContents(_ table: NSTableView) {
            let ids = parent.items.map(\.id)
            if ids != displayedIDs {
                displayedIDs = ids
                table.reloadData()
            }
            // Reflect the current sort order in the header indicator.
            table.sortDescriptors = parent.sortOrder.first.map { descriptorFor($0) }.map { [$0] } ?? []
        }

        func syncSelection(_ table: NSTableView) {
            let target = IndexSet(parent.items.enumerated()
                .filter { parent.selection.contains($0.element.id) }
                .map(\.offset))
            if table.selectedRowIndexes != target {
                isSyncingSelection = true
                table.selectRowIndexes(target, byExtendingSelection: false)
                isSyncingSelection = false
            }
        }

        // MARK: Data

        func numberOfRows(in tableView: NSTableView) -> Int { parent.items.count }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard row < parent.items.count, let columnID = tableColumn?.identifier.rawValue else { return nil }
            let item = parent.items[row]
            let id = NSUserInterfaceItemIdentifier(columnID)
            let cell = (tableView.makeView(withIdentifier: id, owner: self) as? NSTableCellView) ?? makeCell(id: id, withIcon: columnID == Column.name)

            switch columnID {
            case Column.name:
                cell.textField?.stringValue = item.name
                cell.imageView?.image = NSImage(systemSymbolName: item.isDirectory ? "folder" : "doc",
                                                accessibilityDescription: nil)
            case Column.size:
                cell.textField?.stringValue = item.size.map { Self.sizeFormatter.string(fromByteCount: $0) } ?? "—"
            case Column.date:
                cell.textField?.stringValue = item.modificationDate.map(Self.dateFormatter.string(from:)) ?? "—"
            default: break
            }
            return cell
        }

        private func makeCell(id: NSUserInterfaceItemIdentifier, withIcon: Bool) -> NSTableCellView {
            let cell = NSTableCellView()
            cell.identifier = id
            let text = NSTextField(labelWithString: "")
            text.translatesAutoresizingMaskIntoConstraints = false
            text.lineBreakMode = .byTruncatingTail
            cell.addSubview(text)
            cell.textField = text
            if withIcon {
                let image = NSImageView()
                image.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(image)
                cell.imageView = image
                NSLayoutConstraint.activate([
                    image.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                    image.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                    image.widthAnchor.constraint(equalToConstant: 16),
                    image.heightAnchor.constraint(equalToConstant: 16),
                    text.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 6),
                    text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
                    text.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                ])
            } else {
                NSLayoutConstraint.activate([
                    text.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                    text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
                    text.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                ])
            }
            return cell
        }

        // MARK: Selection

        func tableViewSelectionDidChange(_ notification: Notification) {
            guard !isSyncingSelection, let table = notification.object as? NSTableView else { return }
            let ids = table.selectedRowIndexes.compactMap { $0 < parent.items.count ? parent.items[$0].id : nil }
            parent.selection = Set(ids)
        }

        // MARK: Sorting

        func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
            guard let descriptor = tableView.sortDescriptors.first, let key = descriptor.key else { return }
            let order: SortOrder = descriptor.ascending ? .forward : .reverse
            switch key {
            case Column.size: parent.sortOrder = [KeyPathComparator(\FileItem.sizeForSort, order: order)]
            case Column.date: parent.sortOrder = [KeyPathComparator(\FileItem.dateForSort, order: order)]
            default: parent.sortOrder = [KeyPathComparator(\FileItem.name, order: order)]
            }
        }

        private func descriptorFor(_ comparator: KeyPathComparator<FileItem>) -> NSSortDescriptor {
            let ascending = comparator.order == .forward
            let key: String
            switch comparator.keyPath {
            case \FileItem.sizeForSort: key = Column.size
            case \FileItem.dateForSort: key = Column.date
            default: key = Column.name
            }
            return NSSortDescriptor(key: key, ascending: ascending)
        }

        // MARK: Drag source

        func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
            guard row < parent.items.count else { return nil }
            return parent.items[row].url as NSURL
        }

        // MARK: Drop target

        func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo,
                       proposedRow row: Int, proposedDropOperation op: NSTableView.DropOperation) -> NSDragOperation {
            // Drop ON a folder row -> into it; otherwise -> the Panel's directory.
            if op == .on, row < parent.items.count, parent.items[row].isDirectory {
                return .copy
            }
            if op == .on { tableView.setDropRow(-1, dropOperation: .above) } // retarget non-folder rows to background
            return .copy
        }

        func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo,
                       row: Int, dropOperation op: NSTableView.DropOperation) -> Bool {
            let urls = (info.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL]) ?? []
            guard !urls.isEmpty else { return false }
            let targetFolder: FileItem? = (op == .on && row < parent.items.count && parent.items[row].isDirectory)
                ? parent.items[row] : nil
            parent.onDrop(urls, targetFolder)
            return true
        }
    }
}
