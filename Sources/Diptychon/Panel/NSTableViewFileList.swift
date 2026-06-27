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
    let renameRequest: UUID?
    let onRename: (_ item: FileItem, _ newName: String) -> Bool

    init(
        items: [FileItem],
        selection: Binding<Set<FileItem.ID>>,
        sortOrder: Binding<[KeyPathComparator<FileItem>]>,
        onDrop: @escaping (_ urls: [URL], _ targetFolder: FileItem?) -> Void,
        onPin: @escaping (_ folder: URL) -> Void,
        renameRequest: UUID?,
        onRename: @escaping (_ item: FileItem, _ newName: String) -> Bool
    ) {
        self.items = items
        self._selection = selection
        self._sortOrder = sortOrder
        self.onDrop = onDrop
        self.onPin = onPin
        self.renameRequest = renameRequest
        self.onRename = onRename
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
        table.beginEdit = { [weak coordinator = context.coordinator] row in
            coordinator?.beginEditing(row: row)
        }

        addColumn(table, id: Column.name, title: "Name", width: 210, sortKey: "name")
        addColumn(table, id: Column.size, title: "Size", width: 90, sortKey: "size", alignment: .right)
        addColumn(table, id: Column.date, title: "Date Modified", width: 160, sortKey: "date")

        // Issue 17: Name starts at a compact width and the user's drag-resize sticks
        // (only the last column auto-resizes on window changes, so Name is left
        // alone). Date takes up any slack on wide windows → no trailing gap; narrow
        // panels scroll to reach Size/Date. Name truncates with “…” (name in tooltip).
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        if let nameCol = table.tableColumn(withIdentifier: .init(Column.name)) {
            nameCol.minWidth = 120
            nameCol.maxWidth = .greatestFiniteMagnitude
        }

        // Drag out (to Finder / other Panel) + accept drops (from Finder / Panels).
        table.setDraggingSourceOperationMask(.copy, forLocal: true)
        table.setDraggingSourceOperationMask(.copy, forLocal: false)
        table.registerForDraggedTypes([.fileURL])

        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        // Narrow panels scroll to reach Size/Date rather than hiding them; columns
        // also stay user-resizable/reorderable (issue 17).
        scroll.hasHorizontalScroller = true
        context.coordinator.table = table
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let table = scroll.documentView as? NSTableView else { return }
        context.coordinator.syncContents(table)
        context.coordinator.syncSelection(table)
        context.coordinator.handleRenameRequest(table)
    }

    private func addColumn(_ table: NSTableView, id: String, title: String, width: CGFloat,
                           sortKey: String, alignment: NSTextAlignment = .left) {
        let col = NSTableColumn(identifier: .init(id))
        col.title = title
        col.width = width
        col.headerCell.alignment = alignment   // header matches the cell alignment
        col.sortDescriptorPrototype = NSSortDescriptor(key: sortKey, ascending: true)
        table.addTableColumn(col)
    }

    enum Column { static let name = "name", size = "size", date = "date" }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
        var parent: NSTableViewFileList
        weak var table: NSTableView?
        private var displayedIDs: [FileItem.ID] = []
        /// Last inline-rename token handled, so a new request edits exactly once.
        private var lastRenameRequest: UUID?
        /// Breaks the AppKit↔SwiftUI selection feedback loop (echo suppression +
        /// reentrancy). The bug-prone rule lives in `SelectionEchoGuard`, tested in
        /// isolation; the Coordinator keeps only the imperative table I/O.
        private var echo = SelectionEchoGuard()

        private static let sizeFormatter: ByteCountFormatter = {
            let f = ByteCountFormatter(); f.countStyle = .file; return f
        }()

        init(_ parent: NSTableViewFileList) { self.parent = parent }

        /// Reload only when the rows actually changed (avoids reload-mid-click).
        func syncContents(_ table: NSTableView) {
            let ids = parent.items.map(\.id)
            if ids != displayedIDs {
                let isNavigation = !displayedIDs.isEmpty   // not the very first fill
                displayedIDs = ids
                table.reloadData()
                // Start scrolled to the left so Name is visible first when a folder
                // loads (issue 17). The user can still scroll right to Size/Date;
                // navigating to another folder returns to Name-first.
                if isNavigation, let clip = table.enclosingScrollView?.contentView {
                    clip.scroll(to: NSPoint(x: 0, y: clip.bounds.origin.y))
                    table.enclosingScrollView?.reflectScrolledClipView(clip)
                }
            }
            // Reflect the current sort order in the header indicator.
            table.sortDescriptors = parent.sortOrder.first.map { descriptorFor($0) }.map { [$0] } ?? []
        }

        func syncSelection(_ table: NSTableView) {
            // Only override when the binding changed externally (not an echo of
            // what the table just published) — otherwise we'd wipe in-progress
            // multi-selection on every unrelated re-render.
            guard echo.shouldApply(parent.selection) else { return }
            let target = IndexSet(parent.items.enumerated()
                .filter { parent.selection.contains($0.element.id) }
                .map(\.offset))
            if table.selectedRowIndexes != target {
                echo.beginApply()
                table.selectRowIndexes(target, byExtendingSelection: false)
                echo.endApply()
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
                if let nameCell = cell as? NameCellView {
                    nameCell.tagDots.setTags(item.tags)
                    // Search-result location after the name; hidden otherwise.
                    nameCell.location.stringValue = item.subtitle ?? ""
                    nameCell.location.isHidden = item.subtitle == nil
                }
                // Full name (+ location while searching) on hover, since it truncates.
                cell.toolTip = item.subtitle.map { "\(item.name) — \($0)" } ?? item.name
            case Column.size:
                cell.textField?.stringValue = item.size.map { Self.sizeFormatter.string(fromByteCount: $0) } ?? "—"
            case Column.date:
                cell.textField?.stringValue = item.modificationDate.map { FileDateFormatter.string(for: $0) } ?? "—"
            default: break
            }
            return cell
        }

        private func makeCell(id: NSUserInterfaceItemIdentifier, withIcon: Bool) -> NSTableCellView {
            let cell = withIcon ? NameCellView() : NSTableCellView()
            cell.identifier = id
            // Name cell uses an editable field (inline rename, issue 11) styled like
            // a label; AppKit gives slow-click-to-edit for free once it's editable.
            // It reports as *static text* to accessibility until actually editing
            // (see EditableNameTextField), so VoiceOver + UI tests still see labels.
            let text: NSTextField = withIcon ? EditableNameTextField() : NSTextField(labelWithString: "")
            text.translatesAutoresizingMaskIntoConstraints = false
            text.lineBreakMode = .byTruncatingTail
            if withIcon {
                // Editable only *while* renaming (issue 11) — kept non-editable
                // otherwise so a normal click selects the row (doesn't steal focus).
                text.isBordered = false
                text.isBezeled = false
                text.drawsBackground = false
                text.isEditable = false
                text.isSelectable = false
                text.focusRingType = .none
                text.font = .systemFont(ofSize: NSFont.systemFontSize)
                text.delegate = self
            }
            // Numeric Size column → right-aligned + monospaced digits so values
            // line up by place value for at-a-glance comparison (issue 17).
            if id.rawValue == Column.size {
                text.alignment = .right
                text.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            }
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
                let location = cell.location
                cell.addSubview(location)
                NSLayoutConstraint.activate([
                    image.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                    image.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                    image.widthAnchor.constraint(equalToConstant: 16),
                    image.heightAnchor.constraint(equalToConstant: 16),
                    text.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 6),
                    text.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                    // Name → location (search) → tag dots, all on one line; name
                    // truncates before the location, location before nothing.
                    location.leadingAnchor.constraint(equalTo: text.trailingAnchor, constant: 8),
                    location.firstBaselineAnchor.constraint(equalTo: text.firstBaselineAnchor),
                    dots.leadingAnchor.constraint(equalTo: location.trailingAnchor, constant: 6),
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
            guard let table = notification.object as? NSTableView else { return }
            let ids = Set(table.selectedRowIndexes.compactMap { $0 < parent.items.count ? parent.items[$0].id : nil })
            // nil while we're applying a programmatic selection (our own echo).
            guard let published = echo.captureFromTable(ids) else { return }
            parent.selection = published
        }

        // MARK: Inline rename (issue 11)

        /// ⌘R on a single row bumps `renameRequest`; begin editing that row's name.
        func handleRenameRequest(_ table: NSTableView) {
            guard let request = parent.renameRequest, request != lastRenameRequest else { return }
            lastRenameRequest = request
            beginEditing(row: table.selectedRow)
        }

        /// Start an inline rename of `row`: flip the name field editable just for the
        /// edit (it's non-editable otherwise so clicks select normally) and focus it.
        /// Shared by ⌘R and slow-click.
        func beginEditing(row: Int) {
            guard let table = table, row >= 0, row < parent.items.count else { return }
            let nameColumn = table.column(withIdentifier: .init(Column.name))
            guard nameColumn >= 0 else { return }
            if let cell = table.view(atColumn: nameColumn, row: row, makeIfNecessary: true) as? NSTableCellView {
                cell.textField?.isEditable = true
            }
            table.editColumn(nameColumn, row: row, with: nil, select: false)
        }

        /// Pre-select the base name (extension stays put) when editing starts.
        func controlTextDidBeginEditing(_ obj: Notification) {
            guard let field = obj.object as? NSTextField, let editor = field.currentEditor() else { return }
            let base = (field.stringValue as NSString).deletingPathExtension
            editor.selectedRange = NSRange(location: 0, length: (base as NSString).length)
        }

        /// Commit on Return / click-away (one undoable RenameOperation); revert on
        /// Escape, an empty/unchanged name, or a rejected (colliding) name.
        func controlTextDidEndEditing(_ obj: Notification) {
            guard let field = obj.object as? NSTextField, let table = table else { return }
            defer { field.isEditable = false }            // back to non-editable (selectable) label
            let row = table.row(for: field)
            guard row >= 0, row < parent.items.count else { return }
            let item = parent.items[row]
            let movement = (obj.userInfo?["NSTextMovement"] as? Int).flatMap(NSTextMovement.init(rawValue:))
            if movement == .cancel {                      // Escape
                field.stringValue = item.name
                return
            }
            if !parent.onRename(item, field.stringValue) {
                field.stringValue = item.name             // rejected / unchanged → revert
            }
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
    /// Begin an inline rename of a row (slow-click, issue 11). Set by the coordinator.
    var beginEdit: ((Int) -> Void)?
    private var pendingEdit: DispatchWorkItem?

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        return menuProvider?(row(at: point))
    }

    /// Finder-style slow-click rename: a single click on the row that was *already*
    /// the sole selection (no drag, no double-click) begins editing after the
    /// double-click window. Double-click (open) cancels it; a drag skips it.
    override func mouseDown(with event: NSEvent) {
        let downPoint = convert(event.locationInWindow, from: nil)
        let clickedRow = row(at: downPoint)
        let wasSoleSelection = clickedRow >= 0 && selectedRowIndexes.count == 1 && selectedRow == clickedRow
        pendingEdit?.cancel(); pendingEdit = nil

        super.mouseDown(with: event)   // selection + any row-drag tracking

        guard event.clickCount == 1, clickedRow >= 0, wasSoleSelection else { return }
        let up = convert(window?.mouseLocationOutsideOfEventStream ?? .zero, from: nil)
        guard abs(up.x - downPoint.x) < 4, abs(up.y - downPoint.y) < 4 else { return }  // dragged → skip
        let work = DispatchWorkItem { [weak self] in self?.beginEdit?(clickedRow) }
        pendingEdit = work
        DispatchQueue.main.asyncAfter(deadline: .now() + NSEvent.doubleClickInterval + 0.05, execute: work)
    }
}

/// Name-column cell that also carries a trailing tag-dots view.
final class NameCellView: NSTableCellView {
    let tagDots = FinderTagDotsView()
    /// Search-result location (issue 21 slice 3): the match's folder, shown gray
    /// after the name. Hidden (and zero-width) outside search.
    let location: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingHead   // keep the tail folder visible
        // Yield width before the name does, and never expand past its content.
        label.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()
}

/// Editable name field (inline rename, issue 11) that reports as **static text**
/// to accessibility while it's not being edited — so VoiceOver reads the list as
/// labels and XCUITest keeps finding rows via `staticTexts[name]`. Once the field
/// editor is active it reports as a text field.
final class EditableNameTextField: NSTextField {
    override func accessibilityRole() -> NSAccessibility.Role? {
        currentEditor() == nil ? .staticText : .textField
    }

    /// Transparent to the mouse unless actively editing — so a click selects the
    /// row and a right-click hits the table's row menu (not the field), exactly
    /// like a plain label. Editing is driven programmatically via `editColumn`
    /// (⌘R / slow-click), after which `currentEditor()` is non-nil and normal
    /// hit-testing resumes so the field editor is interactive. (Issue 11.)
    override func hitTest(_ point: NSPoint) -> NSView? {
        currentEditor() == nil ? nil : super.hitTest(point)
    }
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
