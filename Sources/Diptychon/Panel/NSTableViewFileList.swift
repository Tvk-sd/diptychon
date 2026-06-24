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
    let onPin: (_ folder: URL) -> Void

    init(
        items: [FileItem],
        selection: Binding<Set<FileItem.ID>>,
        sortOrder: Binding<[KeyPathComparator<FileItem>]>,
        onDrop: @escaping (_ urls: [URL], _ targetFolder: FileItem?) -> Void,
        onPin: @escaping (_ folder: URL) -> Void
    ) {
        self.items = items
        self._selection = selection
        self._sortOrder = sortOrder
        self.onDrop = onDrop
        self.onPin = onPin
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let table = FileTableView()
        table.style = .inset
        table.usesAlternatingRowBackgroundColors = true
        table.allowsMultipleSelection = true
        table.dataSource = context.coordinator
        table.delegate = context.coordinator
        table.target = context.coordinator
        table.rowHeight = 24
        // Right-click "Open / Open With…" menu, built for the clicked row.
        table.menuProvider = { [weak coordinator = context.coordinator] row in
            coordinator?.contextMenu(forRow: row)
        }

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
        /// The selection we last pushed to the binding. Lets us tell a binding
        /// change that *we* caused (echo) from one made externally (e.g. nav
        /// clearing selection) — only the latter should override the table.
        private var lastPublished = Set<FileItem.ID>()

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
            // Only override when the binding changed externally (not an echo of
            // what the table just published) — otherwise we'd wipe in-progress
            // multi-selection on every unrelated re-render.
            guard parent.selection != lastPublished else { return }
            lastPublished = parent.selection
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
                (cell as? NameCellView)?.tagDots.setTags(item.tags)
            case Column.size:
                cell.textField?.stringValue = item.size.map { Self.sizeFormatter.string(fromByteCount: $0) } ?? "—"
            case Column.date:
                cell.textField?.stringValue = item.modificationDate.map(Self.dateFormatter.string(from:)) ?? "—"
            default: break
            }
            return cell
        }

        private func makeCell(id: NSUserInterfaceItemIdentifier, withIcon: Bool) -> NSTableCellView {
            let cell = withIcon ? NameCellView() : NSTableCellView()
            cell.identifier = id
            let text = NSTextField(labelWithString: "")
            text.translatesAutoresizingMaskIntoConstraints = false
            text.lineBreakMode = .byTruncatingTail
            cell.addSubview(text)
            cell.textField = text
            if withIcon, let cell = cell as? NameCellView {
                let image = NSImageView()
                image.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(image)
                cell.imageView = image
                let dots = cell.tagDots
                dots.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(dots)
                NSLayoutConstraint.activate([
                    image.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                    image.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                    image.widthAnchor.constraint(equalToConstant: 16),
                    image.heightAnchor.constraint(equalToConstant: 16),
                    text.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 6),
                    text.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                    // Tag dots sit at the trailing edge; the name truncates before them.
                    dots.leadingAnchor.constraint(equalTo: text.trailingAnchor, constant: 6),
                    dots.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
                    dots.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                ])
                dots.setContentHuggingPriority(.required, for: .horizontal)
                dots.setContentCompressionResistancePriority(.required, for: .horizontal)
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
            let ids = Set(table.selectedRowIndexes.compactMap { $0 < parent.items.count ? parent.items[$0].id : nil })
            lastPublished = ids
            parent.selection = ids
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

        // MARK: Context menu (Open / Open With)

        /// A request to open files with a specific app (`app == nil` → "Other…").
        private struct OpenWithRequest { let urls: [URL]; let app: URL? }

        /// Build the right-click menu for the clicked row. Targets the selection if
        /// the clicked row is part of it, else just the clicked row (Finder behavior).
        func contextMenu(forRow row: Int) -> NSMenu? {
            let urls = targetURLs(forClickedRow: row)
            guard !urls.isEmpty, let first = urls.first else { return nil }

            let menu = NSMenu()
            let open = NSMenuItem(title: "Open", action: #selector(openClicked(_:)), keyEquivalent: "")
            open.target = self
            open.representedObject = urls
            menu.addItem(open)

            let openWith = NSMenuItem(title: "Open With", action: nil, keyEquivalent: "")
            let sub = NSMenu()
            for app in NSWorkspace.shared.urlsForApplications(toOpen: first) {
                let mi = NSMenuItem(title: FileManager.default.displayName(atPath: app.path),
                                    action: #selector(openWithApp(_:)), keyEquivalent: "")
                mi.target = self
                let icon = NSWorkspace.shared.icon(forFile: app.path)
                icon.size = NSSize(width: 16, height: 16)
                mi.image = icon
                mi.representedObject = OpenWithRequest(urls: urls, app: app)
                sub.addItem(mi)
            }
            if !sub.items.isEmpty { sub.addItem(.separator()) }
            let other = NSMenuItem(title: "Other…", action: #selector(openWithOther(_:)), keyEquivalent: "")
            other.target = self
            other.representedObject = urls
            sub.addItem(other)
            openWith.submenu = sub
            menu.addItem(openWith)

            // "Add to Sidebar" for a single folder (issue 16, slice 2). Finder
            // pins one folder at a time, so this only appears for a lone folder.
            if urls.count == 1, parent.items.contains(where: { $0.url == first && $0.isDirectory }) {
                menu.addItem(.separator())
                let pin = NSMenuItem(title: "Add to Sidebar", action: #selector(pinClicked(_:)), keyEquivalent: "")
                pin.target = self
                pin.representedObject = first
                menu.addItem(pin)
            }
            return menu
        }

        /// URLs the menu acts on: the selection if the clicked row is in it,
        /// otherwise the clicked row alone (which we also select, like Finder).
        private func targetURLs(forClickedRow row: Int) -> [URL] {
            guard row >= 0, row < parent.items.count else { return [] }
            let clickedID = parent.items[row].id
            let selectedIDs = Set(table?.selectedRowIndexes
                .compactMap { $0 < parent.items.count ? parent.items[$0].id : nil } ?? [])
            let ids: Set<FileItem.ID>
            if selectedIDs.contains(clickedID) {
                ids = selectedIDs
            } else {
                ids = [clickedID]
                table?.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            }
            return parent.items.filter { ids.contains($0.id) }.map(\.url)
        }

        @objc private func pinClicked(_ sender: NSMenuItem) {
            guard let url = sender.representedObject as? URL else { return }
            parent.onPin(url)
        }

        @objc private func openClicked(_ sender: NSMenuItem) {
            guard let urls = sender.representedObject as? [URL] else { return }
            urls.forEach { NSWorkspace.shared.open($0) }
        }

        @objc private func openWithApp(_ sender: NSMenuItem) {
            guard let req = sender.representedObject as? OpenWithRequest, let app = req.app else { return }
            NSWorkspace.shared.open(req.urls, withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
        }

        @objc private func openWithOther(_ sender: NSMenuItem) {
            guard let urls = sender.representedObject as? [URL] else { return }
            let panel = NSOpenPanel()
            panel.directoryURL = URL(fileURLWithPath: "/Applications")
            panel.allowedContentTypes = [.application]
            panel.allowsMultipleSelection = false
            guard panel.runModal() == .OK, let app = panel.url else { return }
            NSWorkspace.shared.open(urls, withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
        }
    }
}

/// `NSTableView` that serves a right-click menu built for the row under the
/// cursor (so "Open With" can target the clicked file even if unselected).
final class FileTableView: NSTableView {
    var menuProvider: ((Int) -> NSMenu?)?

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        return menuProvider?(row(at: point))
    }
}

/// Name-column cell that also carries a trailing tag-dots view.
final class NameCellView: NSTableCellView {
    let tagDots = FinderTagDotsView()
}

/// A trailing row of up to 3 tag color dots, then "+N" if there are more. The
/// tooltip + accessibility label carry the tag names, so the row shows both color
/// and name (AC1) without crowding the filename.
final class FinderTagDotsView: NSStackView {
    private static let maxDots = 3

    override init(frame: NSRect) {
        super.init(frame: frame)
        orientation = .horizontal
        spacing = 3
        alignment = .centerY
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setTags(_ tags: [FinderTag]) {
        arrangedSubviews.forEach { $0.removeFromSuperview() } // cells are reused.
        let names = tags.map(\.name).joined(separator: ", ")
        toolTip = tags.isEmpty ? nil : names
        setAccessibilityLabel(tags.isEmpty ? nil : "Tags: \(names)")

        guard !tags.isEmpty else { return }
        for tag in tags.prefix(Self.maxDots) { addArrangedSubview(Self.makeDot(for: tag.color)) }
        if tags.count > Self.maxDots {
            let label = NSTextField(labelWithString: "+\(tags.count - Self.maxDots)")
            label.font = .systemFont(ofSize: 10)
            label.textColor = .secondaryLabelColor
            addArrangedSubview(label)
        }
    }

    private static func makeDot(for color: FinderTagColor) -> NSView {
        let size: CGFloat = 9
        let dot = NSView()
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.wantsLayer = true
        dot.layer?.cornerRadius = size / 2
        if let fill = color.nsColor {
            dot.layer?.backgroundColor = fill.cgColor
        } else { // no-color tag: hollow gray ring so it still reads as "tagged".
            dot.layer?.borderWidth = 1
            dot.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        }
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: size),
            dot.heightAnchor.constraint(equalToConstant: size),
        ])
        return dot
    }
}

extension FinderTagColor {
    /// On-screen color for a tag dot, or `nil` for a no-color tag.
    var nsColor: NSColor? {
        switch self {
        case .none: return nil
        case .gray: return .systemGray
        case .green: return .systemGreen
        case .purple: return .systemPurple
        case .blue: return .systemBlue
        case .yellow: return .systemYellow
        case .red: return .systemRed
        case .orange: return .systemOrange
        }
    }
}
