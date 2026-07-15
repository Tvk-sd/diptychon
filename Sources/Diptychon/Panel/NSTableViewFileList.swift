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
    /// Add the given files to the virtual staging set (issue 20) — context menu.
    let onAddToStaging: (_ urls: [URL]) -> Void
    /// Remove files from the staging set (issue 33). Non-nil only for the Staging
    /// pane's list — its presence swaps "Add to Staging" for "Remove from Staging".
    let onRemoveFromStaging: ((_ urls: [URL]) -> Void)?
    /// Activate (open file / navigate folder) a single **clicked** row on double-click
    /// (issue 25). Sourced from the clicked row, not the selection. Non-nil only where
    /// double-click should act (the file panels).
    let onActivate: ((_ item: FileItem) -> Void)?
    let renameRequest: UUID?
    let onRename: (_ item: FileItem, _ newName: String) -> Bool
    /// A row to weakly grey-highlight and scroll into view (a path-paste jump's
    /// landing file). Distinct from selection; `nil` in normal use.
    var highlightedTargetID: FileItem.ID? = nil
    /// When true, this list is the keyboard home of the Active Panel and claims
    /// first responder (issue 53) — ↑/↓ are native table navigation, so they follow
    /// the AppKit first responder, which Tab (`switchPanel`) alone never moved.
    var claimsKeyFocus = false
    /// Stable accessibility identifier for the table (e.g. `panel-left`), so UI
    /// tests target a panel by id rather than a positional `boundBy:` index — the
    /// sidebar `List` also surfaces as a `table`, breaking index assumptions
    /// (issue 23).
    let accessibilityID: String

    init(
        items: [FileItem],
        selection: Binding<Set<FileItem.ID>>,
        sortOrder: Binding<[KeyPathComparator<FileItem>]>,
        onDrop: @escaping (_ urls: [URL], _ targetFolder: FileItem?) -> Void,
        onPin: @escaping (_ folder: URL) -> Void,
        onAddToStaging: @escaping (_ urls: [URL]) -> Void = { _ in },
        onRemoveFromStaging: ((_ urls: [URL]) -> Void)? = nil,
        onActivate: ((_ item: FileItem) -> Void)? = nil,
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
        self.onRemoveFromStaging = onRemoveFromStaging
        self.onActivate = onActivate
        self.renameRequest = renameRequest
        self.onRename = onRename
        self.accessibilityID = accessibilityID
    }

    /// Fluent setter for the path-paste landing highlight, kept off the protocol
    /// `init` (ADR 0002) so the swap-point signature stays minimal.
    func highlightingTarget(_ id: FileItem.ID?) -> Self {
        var copy = self
        copy.highlightedTargetID = id
        return copy
    }

    /// Fluent setter mirroring `highlightingTarget`: keyboard focus follows the
    /// Active Panel. Kept off the protocol `init` for the same reason.
    func claimingKeyFocus(_ claims: Bool) -> Self {
        var copy = self
        copy.claimsKeyFocus = claims
        return copy
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let table = FileTableView()
        table.setAccessibilityIdentifier(accessibilityID)
        table.style = .fullWidth
        table.usesAlternatingRowBackgroundColors = true
        table.allowsMultipleSelection = true
        table.dataSource = context.coordinator
        table.delegate = context.coordinator
        table.target = context.coordinator
        // Double-click opens/navigates the CLICKED row only (issue 25). AppKit's
        // doubleAction reports `clickedRow`, so the target is the row under the
        // cursor — never the lingering multi-selection.
        table.doubleAction = #selector(Coordinator.tableDoubleClicked(_:))
        table.rowHeight = 24
        // Right-click "Open / Open With…" menu, built for the clicked row.
        table.menuProvider = { [weak coordinator = context.coordinator] row in
            coordinator?.contextMenu(forRow: row)
        }
        table.beginEdit = { [weak coordinator = context.coordinator] row in
            coordinator?.beginEditing(row: row)
        }

        // Order: Name (flexes) · Kind · Modified · Size. Compact widths; all
        // user-resizable (issue 29).
        addColumn(table, id: Column.name, title: "Name", width: 180, sortKey: "name")
        addColumn(table, id: Column.kind, title: "Type", width: 100, sortKey: "kind")
        addColumn(table, id: Column.date, title: "Date", width: 140, sortKey: "date")
        addColumn(table, id: Column.size, title: "Size", width: 70, sortKey: "size", alignment: .right)

        // Name is the flexible column: it absorbs window-resize slack while Kind /
        // Modified / Size keep their set widths, so they stay grouped right after Name
        // with no trailing gap (issue 29). On a narrow window Name shrinks to its
        // minWidth and the panel scrolls to reach them. Name truncates with “…”
        // (full name in the tooltip).
        table.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
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
        context.coordinator.syncTargetHighlight(table)
        context.coordinator.handleRenameRequest(table)
        // Claim keyboard focus for the Active Panel — but only from the other
        // panel's table (or from nothing), never from a text field, so typing in
        // Search/Filter or an inline rename is never interrupted.
        if claimsKeyFocus, let window = scroll.window,
           window.firstResponder !== table,
           window.firstResponder === window || window.firstResponder is FileTableView {
            window.makeFirstResponder(table)
        }
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

    enum Column { static let name = "name", size = "size", date = "date", kind = "kind" }

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
                // A reload can move/clear the table's selection (rows vanished);
                // that is NOT user input and must never publish back into the
                // model — it would overwrite a fresh model-side selection (the
                // issue-53 post-trash reselect lost its race here). Suppress the
                // echo; `syncSelection` right after reconciles table ← model.
                echo.beginApply()
                table.reloadData()
                echo.endApply()
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

        /// Reflect the path-paste landing highlight: grey the target row (visible
        /// rows are updated in place; off-screen ones get it via `rowViewForRow`)
        /// and scroll it into view once, when it first appears.
        private var lastScrolledTarget: FileItem.ID?
        func syncTargetHighlight(_ table: NSTableView) {
            let targetRow = parent.highlightedTargetID.flatMap { id in
                parent.items.firstIndex { $0.id == id }
            }
            table.enumerateAvailableRowViews { rowView, index in
                (rowView as? HoverRowView)?.isTarget = (index == targetRow)
            }
            if let targetRow, parent.highlightedTargetID != lastScrolledTarget {
                lastScrolledTarget = parent.highlightedTargetID
                table.scrollRowToVisible(targetRow)
            } else if parent.highlightedTargetID == nil {
                lastScrolledTarget = nil
            }
        }

        // MARK: Data

        func numberOfRows(in tableView: NSTableView) -> Int { parent.items.count }

        /// Custom row view so the table can paint a hover background under the pointer.
        func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
            let view = HoverRowView()
            // Seed the landing highlight on creation so an off-screen target already
            // reads as highlighted the moment it's scrolled into view.
            if row < parent.items.count, parent.items[row].id == parent.highlightedTargetID {
                view.isTarget = true
            }
            return view
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard row < parent.items.count, let columnID = tableColumn?.identifier.rawValue else { return nil }
            let item = parent.items[row]
            let id = NSUserInterfaceItemIdentifier(columnID)
            let cell = (tableView.makeView(withIdentifier: id, owner: self) as? NSTableCellView) ?? makeCell(id: id, withIcon: columnID == Column.name)

            // Dim hidden files (only ever present when "show hidden" is on) so they
            // read as secondary. Reset every time — cells are reused across rows.
            // Dim hidden files and staged items whose file is gone (issue 20/33).
            cell.alphaValue = (item.isHidden || item.isMissing) ? 0.45 : 1.0

            switch columnID {
            case Column.name:
                cell.textField?.stringValue = item.name
                // Real file-type icon (resolved by extension, cached — no per-file
                // disk hit; see FileIconProvider) instead of a generic SF Symbol.
                cell.imageView?.image = FileIconProvider.icon(for: item)
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
            case Column.kind:
                cell.textField?.stringValue = item.kind
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
                    // Tag dots sit in a fixed right-aligned column pinned to the
                    // cell's trailing edge (under the Name sort arrow), so they line
                    // up across rows instead of trailing each name. The dots stack is
                    // content-sized (required hugging) and pinned by *trailing only*,
                    // so the dot hugs the right edge rather than floating at the left
                    // of a stretched frame. The name/location are bounded by the dots'
                    // leading (`<=`) so a long name truncates before the dot column.
                    location.leadingAnchor.constraint(equalTo: text.trailingAnchor, constant: 8),
                    location.firstBaselineAnchor.constraint(equalTo: text.firstBaselineAnchor),
                    location.trailingAnchor.constraint(lessThanOrEqualTo: dots.leadingAnchor, constant: -8),
                    // +2 nudges the dot just past the content edge so it centers under
                    // the header's sort arrow (which sits in the indicator zone beyond
                    // the cell's content trailing).
                    dots.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: 2),
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
            case Column.kind: parent.sortOrder = [KeyPathComparator(\FileItem.kind, order: order)]
            default: parent.sortOrder = [KeyPathComparator(\FileItem.name, order: order)]
            }
        }

        private func descriptorFor(_ comparator: KeyPathComparator<FileItem>) -> NSSortDescriptor {
            let ascending = comparator.order == .forward
            let key: String
            switch comparator.keyPath {
            case \FileItem.sizeForSort: key = Column.size
            case \FileItem.dateForSort: key = Column.date
            case \FileItem.kind: key = Column.kind
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

            // In the Staging pane: "Remove from Staging" (unstage, no disk delete).
            // Everywhere else: "Add to Staging" — gather these files into the set
            // (issue 20), regardless of which folder they live in.
            menu.addItem(.separator())
            if parent.onRemoveFromStaging != nil {
                let unstage = NSMenuItem(title: "Remove from Staging",
                                         action: #selector(removeFromStagingClicked(_:)), keyEquivalent: "")
                unstage.target = self
                unstage.representedObject = urls
                menu.addItem(unstage)
            } else {
                let stage = NSMenuItem(title: "Add to Staging", action: #selector(addToStagingClicked(_:)), keyEquivalent: "")
                stage.target = self
                stage.representedObject = urls
                menu.addItem(stage)
            }

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

        @objc private func addToStagingClicked(_ sender: NSMenuItem) {
            guard let urls = sender.representedObject as? [URL] else { return }
            parent.onAddToStaging(urls)
        }

        @objc private func removeFromStagingClicked(_ sender: NSMenuItem) {
            guard let urls = sender.representedObject as? [URL] else { return }
            parent.onRemoveFromStaging?(urls)
        }

        /// Double-click: open/navigate the clicked row only (issue 25). `clickedRow`
        /// is the row under the cursor, independent of the current selection. A
        /// double-click on empty space (`clickedRow < 0`) is ignored.
        @objc func tableDoubleClicked(_ sender: NSTableView) {
            let row = sender.clickedRow
            guard row >= 0, row < parent.items.count else { return }
            parent.onActivate?(parent.items[row])
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

    // MARK: Hover highlight
    // A local `.mouseMoved` monitor (with `acceptsMouseMovedEvents`) is the reliable
    // path: per-row tracking areas don't hand off cleanly, and a table-level tracking
    // area is shadowed by the row/cell subviews. The monitor sees every move.

    private var hoveredRow = -1
    private var moveMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window {
            window.acceptsMouseMovedEvents = true
            if moveMonitor == nil {
                moveMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
                    self?.updateHover(event)
                    return event
                }
            }
        } else if let monitor = moveMonitor {
            NSEvent.removeMonitor(monitor)
            moveMonitor = nil
        }
    }

    private func updateHover(_ event: NSEvent) {
        guard event.window === window else { setHoveredRow(-1); return }
        let point = convert(event.locationInWindow, from: nil)
        setHoveredRow(visibleRect.contains(point) ? row(at: point) : -1)
    }

    /// Apply hover to the visible rows: the matched row on, every other off. Using
    /// `enumerateAvailableRowViews` (not per-row tracking of a previous index) keeps
    /// it correct across row reuse and the two panels' shared mouse monitor.
    private func setHoveredRow(_ newRow: Int) {
        guard newRow != hoveredRow else { return }
        hoveredRow = newRow
        enumerateAvailableRowViews { rowView, index in
            (rowView as? HoverRowView)?.isHovered = (index == newRow)
        }
    }

    deinit {
        if let moveMonitor { NSEvent.removeMonitor(moveMonitor) }
    }
}

/// Row view that shows a subtle background when the owning table marks it hovered,
/// suppressed while selected so the two states never fight. Uses a dedicated overlay
/// subview (inserted below the cells) rather than `drawBackground` / the row's own
/// layer — NSTableView manages those itself (alternating-row colors) and overwrites
/// them, but it leaves a foreign subview alone.
final class HoverRowView: NSTableRowView {
    private let overlay: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 0
        view.layer?.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.16).cgColor
        view.isHidden = true
        return view
    }()

    var isHovered = false {
        didSet { if isHovered != oldValue { updateOverlay() } }
    }
    /// A path-paste jump landed on this row — show the same weak grey as hover, but
    /// persistently, so the user can spot where they arrived.
    var isTarget = false {
        didSet { if isTarget != oldValue { updateOverlay() } }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(overlay, positioned: .below, relativeTo: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    override var isSelected: Bool {
        didSet { if isSelected != oldValue { updateOverlay() } }
    }

    override func layout() {
        super.layout()
        overlay.frame = bounds
    }

    private func updateOverlay() {
        // Re-attach + re-frame defensively: NSTableView reuses row views and can strip
        // foreign subviews, so an overlay added only in init may be gone by hover time.
        if overlay.superview !== self {
            addSubview(overlay, positioned: .below, relativeTo: nil)
        }
        overlay.frame = bounds
        overlay.isHidden = !((isHovered || isTarget) && !isSelected)
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

    /// A filled-circle swatch as a **non-template** image so it keeps its color
    /// inside an `NSMenu`. SwiftUI strips `.foregroundStyle` from menu-item SF
    /// Symbols, which is why the tag-filter dots rendered grey (issue 26); a
    /// non-template `NSImage` survives the bridge. `.none` draws a hollow ring to
    /// match the row dot. Shares `nsColor` as the single color source of truth.
    func menuSwatch(diameter: CGFloat = 10) -> NSImage {
        NSImage(size: NSSize(width: diameter, height: diameter), flipped: false) { rect in
            let path = NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5))
            if let fill = self.nsColor {
                fill.setFill(); path.fill()
            } else {
                NSColor.tertiaryLabelColor.setStroke(); path.lineWidth = 1; path.stroke()
            }
            return true
        }
    }
}
