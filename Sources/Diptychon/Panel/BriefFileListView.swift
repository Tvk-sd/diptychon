import SwiftUI
import AppKit

/// Brief (multi-column) display mode (issue 37): names + icons in 1–3 fixed columns,
/// wrapping **down-then-across** with horizontal scroll — the compact scanning view
/// that sits beside the detailed table (Marta's "Multi-column" model). Names only:
/// Kind/Date/Size stay the table's domain (issues 27/29).
///
/// AppKit `NSCollectionView` for the same reason the list is AppKit (ADR 0002):
/// native virtualization (cells materialize only for the visible rect — the O(visible)
/// posture of issues 01/22 must hold for a 50k-file folder), native selection and
/// geometric arrow-key navigation (Left/Right cross columns, Up/Down move within).
/// Same `FileListView` protocol, so `PanelView` swaps it in untouched.
///
/// Deliberate deltas from the table:
/// - **No column sort headers** — the table's sort order carries over unchanged.
/// - **No inline rename** (no editable cell) — ⌘R on a lone selection opens the
///   batch-rename sheet instead (see `WorkspaceModel.perform(.rename)`).
/// - **No type-select** — NSCollectionView has none; ⌘⇧F (Filter) is the app's
///   type-ahead and keeps working.
struct BriefFileListView: NSViewRepresentable, FileListView {
    let items: [FileItem]
    @Binding var selection: Set<FileItem.ID>
    /// Unused — brief mode has no sortable columns; the table's `sortOrder` feeds
    /// `visibleItems` directly, so the same order shows here.
    @Binding var sortOrder: [KeyPathComparator<FileItem>]
    let onDrop: (_ urls: [URL], _ targetFolder: FileItem?) -> Void
    let onPin: (_ folder: URL) -> Void
    let onAddToStaging: (_ urls: [URL]) -> Void
    let onRemoveFromStaging: ((_ urls: [URL]) -> Void)?
    let onActivate: ((_ item: FileItem) -> Void)?
    /// Ignored — no editable cell in brief mode (see the header note).
    let renameRequest: UUID?
    let onRename: (_ item: FileItem, _ newName: String) -> Bool
    /// Fixed column count, 1–3 (issue 37: explicit pick, no auto-fit).
    var columns = 2
    /// See `NSTableViewFileList.claimsKeyFocus` — same Active-Panel contract.
    var claimsKeyFocus = false
    /// Path-paste landing target: scrolled into view (no grey highlight — the brief
    /// cell has no hover/target overlay like `HoverRowView`).
    var highlightedTargetID: FileItem.ID? = nil
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

    /// Fluent setters, same pattern as `NSTableViewFileList` — kept off the protocol
    /// `init` so the ADR-0002 swap-point signature stays minimal.
    func briefColumns(_ n: Int) -> Self { var c = self; c.columns = n; return c }
    func claimingKeyFocus(_ claims: Bool) -> Self { var c = self; c.claimsKeyFocus = claims; return c }
    func highlightingTarget(_ id: FileItem.ID?) -> Self { var c = self; c.highlightedTargetID = id; return c }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let layout = BriefLayout()
        let cv = BriefCollectionView()
        cv.collectionViewLayout = layout
        cv.setAccessibilityIdentifier(accessibilityID)
        cv.isSelectable = true
        cv.allowsMultipleSelection = true
        cv.allowsEmptySelection = true
        cv.backgroundColors = [.clear]
        cv.dataSource = context.coordinator
        cv.delegate = context.coordinator
        cv.register(BriefItem.self, forItemWithIdentifier: BriefItem.identifier)
        cv.onDoubleClick = { [weak coordinator = context.coordinator] index in
            guard let coordinator, index < coordinator.parent.items.count else { return }
            // Same contract as the table's double-click (issue 25): the clicked
            // item only, never the lingering selection.
            coordinator.parent.onActivate?(coordinator.parent.items[index])
        }
        cv.menuProvider = { [weak coordinator = context.coordinator] index in
            coordinator?.contextMenu(forItem: index)
        }
        cv.claimsKeyFocusOnAttach = { [weak coordinator = context.coordinator] in
            coordinator?.parent.claimsKeyFocus ?? false
        }

        // Drag out (Finder / other panel) + accept drops (issue 06 parity).
        cv.setDraggingSourceOperationMask(.copy, forLocal: true)
        cv.setDraggingSourceOperationMask(.copy, forLocal: false)
        cv.registerForDraggedTypes([.fileURL])

        let scroll = NSScrollView()
        scroll.documentView = cv
        // Down-then-across: the grid fits the height exactly and scrolls sideways.
        scroll.hasVerticalScroller = false
        scroll.hasHorizontalScroller = true
        context.coordinator.collectionView = cv
        context.coordinator.layout = layout
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let cv = scroll.documentView as? BriefCollectionView else { return }
        if context.coordinator.layout?.columns != columns {
            context.coordinator.layout?.columns = columns
            cv.collectionViewLayout?.invalidateLayout()
        }
        context.coordinator.syncContents(cv)
        context.coordinator.syncSelection(cv)
        context.coordinator.syncTargetScroll(cv)
        // First-responder claim, same guard as the table: only from the other list
        // or from nothing, never from a text field (Search/Filter/inline rename).
        if claimsKeyFocus, let window = scroll.window,
           window.firstResponder !== cv,
           window.firstResponder === window || window.firstResponder is FileTableView
               || window.firstResponder is BriefCollectionView {
            window.makeFirstResponder(cv)
        }
        cv.claimsKeyFocusOnAttach = { [weak c = context.coordinator] in
            c?.parent.claimsKeyFocus ?? false
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegate {
        var parent: BriefFileListView
        weak var collectionView: BriefCollectionView?
        weak var layout: BriefLayout?
        private var displayedIDs: [FileItem.ID] = []
        /// Same AppKit↔SwiftUI feedback-loop guard the table uses.
        private var echo = SelectionEchoGuard()
        private var lastScrolledTarget: FileItem.ID?

        init(_ parent: BriefFileListView) { self.parent = parent }

        /// Reload only when the rows actually changed (avoids reload-mid-click, same
        /// discipline as the table's `syncContents`).
        func syncContents(_ cv: NSCollectionView) {
            let ids = parent.items.map(\.id)
            guard ids != displayedIDs else { return }
            displayedIDs = ids
            echo.beginApply()
            cv.reloadData()
            echo.endApply()
        }

        func syncSelection(_ cv: NSCollectionView) {
            guard echo.shouldApply(parent.selection) else { return }
            let current = Set(cv.selectionIndexPaths.compactMap {
                $0.item < parent.items.count ? parent.items[$0.item].id : nil
            })
            guard current != parent.selection else { return }
            let target = Set(parent.items.enumerated()
                .filter { parent.selection.contains($0.element.id) }
                .map { IndexPath(item: $0.offset, section: 0) })
            echo.beginApply()
            cv.selectItems(at: target, scrollPosition: [])
            echo.endApply()
        }

        /// A path-paste jump landed on an item — scroll it into view once.
        func syncTargetScroll(_ cv: NSCollectionView) {
            guard let targetID = parent.highlightedTargetID else { lastScrolledTarget = nil; return }
            guard targetID != lastScrolledTarget,
                  let index = parent.items.firstIndex(where: { $0.id == targetID }) else { return }
            lastScrolledTarget = targetID
            cv.scrollToItems(at: [IndexPath(item: index, section: 0)], scrollPosition: .centeredHorizontally)
        }

        // MARK: Data

        func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
            parent.items.count
        }

        func collectionView(_ collectionView: NSCollectionView,
                            itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
            let item = collectionView.makeItem(withIdentifier: BriefItem.identifier, for: indexPath)
            guard let brief = item as? BriefItem, indexPath.item < parent.items.count else { return item }
            brief.configure(parent.items[indexPath.item])
            return brief
        }

        // MARK: Selection

        func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
            publishSelection(collectionView)
        }
        func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
            publishSelection(collectionView)
        }

        private func publishSelection(_ cv: NSCollectionView) {
            let ids = Set(cv.selectionIndexPaths.compactMap {
                $0.item < parent.items.count ? parent.items[$0.item].id : nil
            })
            guard let published = echo.captureFromTable(ids) else { return }
            parent.selection = published
        }

        // MARK: Drag source

        func collectionView(_ collectionView: NSCollectionView,
                            canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool { true }

        func collectionView(_ collectionView: NSCollectionView,
                            pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
            guard indexPath.item < parent.items.count else { return nil }
            return parent.items[indexPath.item].url as NSURL
        }

        // MARK: Drop target

        func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo,
                            proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>,
                            dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
            // Drop ON a folder item → into it; anything else → the panel's directory.
            let index = proposedDropIndexPath.pointee.item
            if proposedDropOperation.pointee == .on,
               index >= 0, index < parent.items.count, parent.items[index].isDirectory {
                return .copy
            }
            proposedDropOperation.pointee = .before   // retarget to background
            return .copy
        }

        func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo,
                            indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
            let urls = (draggingInfo.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL]) ?? []
            guard !urls.isEmpty else { return false }
            let targetFolder: FileItem? = (dropOperation == .on && indexPath.item >= 0
                                           && indexPath.item < parent.items.count
                                           && parent.items[indexPath.item].isDirectory)
                ? parent.items[indexPath.item] : nil
            parent.onDrop(urls, targetFolder)
            return true
        }

        // MARK: Context menu

        /// Right-click menu for the clicked item, mirroring the table's menu
        /// (Open / Open With… / staging / pin). Targets the selection if the clicked
        /// item is part of it, else the clicked item alone (Finder behavior).
        func contextMenu(forItem index: Int) -> NSMenu? {
            let urls = targetURLs(forClickedItem: index)
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

            menu.addItem(.separator())
            if parent.onRemoveFromStaging != nil {
                let unstage = NSMenuItem(title: "Remove from Staging",
                                         action: #selector(removeFromStagingClicked(_:)), keyEquivalent: "")
                unstage.target = self
                unstage.representedObject = urls
                menu.addItem(unstage)
            } else {
                let stage = NSMenuItem(title: "Add to Staging",
                                       action: #selector(addToStagingClicked(_:)), keyEquivalent: "")
                stage.target = self
                stage.representedObject = urls
                menu.addItem(stage)
            }

            if urls.count == 1, parent.items.contains(where: { $0.url == first && $0.isDirectory }) {
                menu.addItem(.separator())
                let pin = NSMenuItem(title: "Add to Sidebar", action: #selector(pinClicked(_:)), keyEquivalent: "")
                pin.target = self
                pin.representedObject = first
                menu.addItem(pin)
            }
            return menu
        }

        /// URLs the menu acts on: the selection if the clicked item is in it,
        /// otherwise the clicked item alone (which we also select, like Finder).
        private func targetURLs(forClickedItem index: Int) -> [URL] {
            guard index >= 0, index < parent.items.count else { return [] }
            let clickedID = parent.items[index].id
            let selectedIDs = Set(collectionView?.selectionIndexPaths
                .compactMap { $0.item < parent.items.count ? parent.items[$0.item].id : nil } ?? [])
            let ids: Set<FileItem.ID>
            if selectedIDs.contains(clickedID) {
                ids = selectedIDs
            } else {
                ids = [clickedID]
                echo.beginApply()
                collectionView?.selectItems(at: [IndexPath(item: index, section: 0)], scrollPosition: [])
                echo.endApply()
            }
            return parent.items.filter { ids.contains($0.id) }.map(\.url)
        }

        private struct OpenWithRequest { let urls: [URL]; let app: URL? }

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
    }
}

// MARK: - Layout

/// Fixed-column grid, **down-then-across**: item *i* sits at column `i / rowsPerColumn`,
/// row `i % rowsPerColumn`, so a column fills top-to-bottom before the next starts
/// (Marta brief mode). The grid fits the visible height exactly and scrolls
/// horizontally.
///
/// **The geometry comes from the scroll view's visible size, never from the collection
/// view's own bounds** — that distinction is the whole reason the first attempt at this
/// feature (`203bd39`) was rejected on sight. The collection view is the scroll view's
/// `documentView`, so AppKit sizes it *from* `collectionViewContentSize`; reading
/// `bounds` back meant the layout consumed its own output. On the first pass bounds are
/// near zero, which gave `rowsPerColumn = 1` and a minimum-width column — one row of
/// names marching sideways, "no visible columns". After that it fed back: wider content
/// → wider document → wider columns, on every pass, because invalidation was
/// unconditional. Read the *viewport*, and both problems are gone.
///
/// Frames are precomputed per `prepare()` (O(n) arithmetic — cheap even at 50k), and
/// the visible range is found by arithmetic rather than by scanning, so both attribute
/// lookup and cell creation stay O(visible). See issues 01/22 for the posture this has
/// to preserve.
final class BriefLayout: NSCollectionViewLayout {
    /// Visible column count (1–3), driven by the pane's display mode.
    var columns = 2

    static let itemHeight: CGFloat = 24
    /// Floor for a column, so a very narrow pane truncates names instead of collapsing
    /// them to nothing.
    private static let minColumnWidth: CGFloat = 80

    private var frames: [CGRect] = []
    private var rowsPerColumn = 1
    private var columnWidth: CGFloat = 100
    private var contentHeight: CGFloat = 0
    /// The viewport the current `frames` were computed for. Invalidation compares
    /// against this instead of firing on every bounds change — the document view's
    /// bounds change as the content grows and while scrolling, neither of which is a
    /// reason to re-lay-out.
    private var lastViewportSize: CGSize = .zero

    /// What the user can actually see: the scroll view's content area, excluding the
    /// scrollers. Falls back to the collection view's bounds only when there is no
    /// scroll view at all (there always is here) so the layout is still defined.
    private var viewportSize: CGSize {
        guard let cv = collectionView else { return .zero }
        if let clip = cv.enclosingScrollView?.contentView {
            return clip.bounds.size
        }
        return cv.bounds.size
    }

    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { frames = []; return }
        let viewport = viewportSize
        lastViewportSize = viewport
        contentHeight = viewport.height
        let count = cv.numberOfItems(inSection: 0)
        rowsPerColumn = max(1, Int(floor(viewport.height / Self.itemHeight)))
        columnWidth = max(Self.minColumnWidth, viewport.width / CGFloat(max(1, columns)))
        frames = (0..<count).map { i in
            CGRect(x: CGFloat(i / rowsPerColumn) * columnWidth,
                   y: CGFloat(i % rowsPerColumn) * Self.itemHeight,
                   width: columnWidth, height: Self.itemHeight)
        }
    }

    override var collectionViewContentSize: NSSize {
        let columnCount = frames.isEmpty ? 0 : (frames.count + rowsPerColumn - 1) / rowsPerColumn
        // Width from the grid, height from the viewport — never from the document view,
        // which is the thing this value defines.
        return NSSize(width: CGFloat(columnCount) * columnWidth, height: contentHeight)
    }

    /// The visible items are a contiguous index range, because the grid is regular:
    /// columns `rect.minX / columnWidth` through `rect.maxX / columnWidth`, each holding
    /// `rowsPerColumn` items. Derived rather than found by scanning — the previous
    /// version tested all 50k frames on every pass, which cell-level virtualization
    /// does not save you from.
    override func layoutAttributesForElements(in rect: CGRect) -> [NSCollectionViewLayoutAttributes] {
        guard !frames.isEmpty, columnWidth > 0 else { return [] }
        let firstColumn = max(0, Int(floor(rect.minX / columnWidth)))
        let lastColumn = max(0, Int(ceil(rect.maxX / columnWidth)))
        let lower = min(firstColumn * rowsPerColumn, frames.count)
        let upper = min((lastColumn + 1) * rowsPerColumn, frames.count)
        guard lower < upper else { return [] }
        return (lower..<upper).compactMap { i in
            // Still intersection-tested, so a partly scrolled column doesn't hand back
            // rows above or below the viewport.
            frames[i].intersects(rect)
                ? layoutAttributesForItem(at: IndexPath(item: i, section: 0))
                : nil
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        guard indexPath.item < frames.count else { return nil }
        let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
        attributes.frame = frames[indexPath.item]
        return attributes
    }

    /// Only a changed **viewport** changes the grid: height sets `rowsPerColumn`, width
    /// sets the column width. Scrolling and content growth both move the document
    /// view's bounds and must not trigger a re-layout — that was half of the feedback
    /// loop that broke the first attempt.
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        viewportSize != lastViewportSize
    }
}

// MARK: - Item view

/// One brief cell: file icon + name, truncated, with the real file-type icon
/// (`FileIconProvider`, cached). Selection paints a rounded background — the table's
/// row-selection analogue. Hidden files and gone staged items dim, same as the table.
final class BriefItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("briefItem")

    private let icon = NSImageView()
    private let label = NSTextField(labelWithString: "")

    override func loadView() {
        let view = NSView()
        view.wantsLayer = true
        self.view = view

        icon.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
        label.font = .systemFont(ofSize: NSFont.systemFontSize)
        view.addSubview(icon)
        view.addSubview(label)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            icon.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 5),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override var isSelected: Bool {
        didSet { updateSelectionAppearance() }
    }

    /// NSCollectionView resets `isSelected` on reuse before `configure` runs — keep
    /// the paint in sync from both sides.
    override func prepareForReuse() {
        super.prepareForReuse()
        updateSelectionAppearance()
    }

    private func updateSelectionAppearance() {
        view.layer?.cornerRadius = 4
        view.layer?.backgroundColor = isSelected
            ? NSColor.selectedContentBackgroundColor.cgColor
            : NSColor.clear.cgColor
    }

    func configure(_ item: FileItem) {
        label.stringValue = item.name
        icon.image = FileIconProvider.icon(for: item)
        // Dim hidden files and staged items whose file is gone (table parity, 20/33).
        view.alphaValue = (item.isHidden || item.isMissing) ? 0.45 : 1.0
        view.toolTip = item.name
        updateSelectionAppearance()
    }
}

// MARK: - Collection view subclass

/// `NSCollectionView` with the two behaviours the base class lacks: double-click to
/// activate the clicked item (issue 25 parity) and a per-item right-click menu.
/// Also claims keyboard focus on attach when it's the Active Panel's list — the
/// same recreate-on-navigation fix as `FileTableView` (issue 53).
final class BriefCollectionView: NSCollectionView {
    var onDoubleClick: ((Int) -> Void)?
    var menuProvider: ((Int) -> NSMenu?)?
    var claimsKeyFocusOnAttach: (() -> Bool)?

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2, let index = itemIndex(at: event) {
            onDoubleClick?(index)
            return
        }
        super.mouseDown(with: event)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        menuProvider?(itemIndex(at: event) ?? -1)
    }

    private func itemIndex(at event: NSEvent) -> Int? {
        let point = convert(event.locationInWindow, from: nil)
        return indexPathForItem(at: point)?.item
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil, claimsKeyFocusOnAttach?() == true {
            DispatchQueue.main.async { [weak self] in
                guard let self, let window = self.window,
                      window.firstResponder !== self,
                      !(window.firstResponder is NSText) else { return }
                window.makeFirstResponder(self)
            }
        }
    }
}
