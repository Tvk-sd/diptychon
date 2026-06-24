import SwiftUI
import AppKit
import Quartz
import Observation

/// Owns both Panels, the active side, and the `OperationCoordinator`. Lives as a
/// reference type so the `NSEvent` key monitor can read live state (active side,
/// models) instead of a stale snapshot.
@MainActor
@Observable
final class WorkspaceModel {
    enum Side { case left, right }

    /// A copy-or-move write paused on the collision-resolution step.
    struct PendingWrite: Identifiable {
        enum Kind { case copy, move }
        let id = UUID()
        let kind: Kind
        let sources: [URL]
        let destinationDirectory: URL
        let refresh: PanelModel
        let collisionCount: Int
    }

    /// An open batch-rename sheet, operating on a snapshot of the selection.
    struct RenameRequest: Identifiable {
        let id = UUID()
        let items: [FileItem]
        let directory: URL
    }

    let left: PanelModel
    let right: PanelModel
    let coordinator = OperationCoordinator()
    private let quickLook = QuickLookController()

    var active: Side = .left
    var pendingWrite: PendingWrite?
    var renaming: RenameRequest?
    /// Whether the tag picker is open for the Active Panel's selection.
    var tagging = false
    /// Whether the Go to Folder sheet is open (issue 15).
    var goingToFolder = false

    /// Whether the inline preview pane is shown (issue 14). Persisted across
    /// launches so it stays where the user left it.
    var previewVisible = UserDefaults.standard.bool(forKey: "previewVisible") {
        didSet { UserDefaults.standard.set(previewVisible, forKey: "previewVisible") }
    }

    /// Whether the left sidebar (places + pinned folders) is shown (issue 16).
    /// Defaults to true (a registered default in `DiptychonApp`). Persisted.
    var sidebarVisible = UserDefaults.standard.bool(forKey: "sidebarVisible") {
        didSet { UserDefaults.standard.set(sidebarVisible, forKey: "sidebarVisible") }
    }

    /// Folders the user pinned to the sidebar (issue 16, slice 2). Backed by a
    /// `[String]` of paths in `UserDefaults`; deduped on add via `PinnedFolders`.
    var pinnedFolders: [URL] = PinnedFolders.decode(
        UserDefaults.standard.stringArray(forKey: "pinnedFolders") ?? []
    ) {
        didSet { UserDefaults.standard.set(PinnedFolders.encode(pinnedFolders), forKey: "pinnedFolders") }
    }

    /// Whether the right file panel is shown (issue 13). Defaults to true (a
    /// registered default in `DiptychonApp`). Hiding it forces the Active Panel to
    /// the left so keyboard/clicks stay coherent.
    var rightPanelVisible = UserDefaults.standard.bool(forKey: "rightPanelVisible") {
        didSet {
            UserDefaults.standard.set(rightPanelVisible, forKey: "rightPanelVisible")
            if !rightPanelVisible { active = .left }
        }
    }

    init() {
        left = PanelModel(directory: .startDirectory)
        right = PanelModel(directory: .startDirectory)
    }

    /// Full Disk Access onboarding (issue 10): called when the app reactivates
    /// (the user may have just granted access in System Settings). If a panel was
    /// blocked by a permission error and access is now available, re-list it so
    /// the folder fills in — no restart (AC3). No global banner: guidance is
    /// shown inline only when a protected folder is actually opened.
    func recheckFullDiskAccess() {
        guard left.accessDenied || right.accessDenied, FullDiskAccess.isGranted else { return }
        refreshBoth()
    }

    var activeModel: PanelModel { active == .left ? left : right }
    var inactiveModel: PanelModel { active == .left ? right : left }

    /// Handle a raw key event (from the local monitor). Returns true if consumed.
    func handleKeyDown(_ event: NSEvent) -> Bool {
        guard let action = Keymap.action(for: event) else { return false }
        perform(action)
        return true
    }

    func perform(_ action: AppAction) {
        switch action {
        case .copyToInactive:
            // No visible inactive target when the right panel is hidden.
            guard rightPanelVisible else { return }
            write(.copy, sources: activeModel.selectionURLs, into: inactiveModel.directory, refresh: inactiveModel)
        case .undo: coordinator.undo(onFinish: refreshBoth)
        case .redo: coordinator.redo(onFinish: refreshBoth)
        case .goUp: activeModel.navigateUp()
        case .switchPanel:
            if !rightPanelVisible {
                rightPanelVisible = true   // Tab brings the right panel back…
                active = .right            // …and moves focus to it.
            } else {
                active = (active == .left) ? .right : .left
            }
        case .clipboardCopy: clipboardCopy()
        case .paste: write(.copy, sources: clipboardURLs(), into: activeModel.directory, refresh: activeModel)
        case .pasteMove: write(.move, sources: clipboardURLs(), into: activeModel.directory, refresh: activeModel)
        case .trash: trashSelection()
        case .duplicate: duplicateSelection()
        case .newFolder: create(.folder)
        case .newFile: create(.file)
        case .rename: beginRename()
        case .showTags: beginTagging()
        case .openSelection: openSelection()
        case .preview: togglePreview()
        case .goToFolder: goingToFolder = true
        case .toggleSidebar: sidebarVisible.toggle()
        }
    }

    // MARK: - Go to Folder / path navigation (issue 15)

    /// Navigate the Active Panel to a typed path. Returns false (and changes
    /// nothing) if the path doesn't resolve to an existing directory.
    @discardableResult
    func navigateActive(toPath raw: String) -> Bool {
        guard let url = PathInput.resolve(raw) else { return false }
        activeModel.go(to: url)
        return true
    }

    /// Navigate the Active Panel to a known directory URL (sidebar click,
    /// breadcrumb). Unlike `toPath`, the URL is already trusted.
    func navigateActive(to url: URL) {
        activeModel.go(to: url)
    }

    // MARK: - Pinned folders (sidebar, issue 16)

    func pin(_ url: URL) { pinnedFolders = PinnedFolders.adding(url, to: pinnedFolders) }
    func unpin(_ url: URL) { pinnedFolders = PinnedFolders.removing(url, from: pinnedFolders) }


    // MARK: - QuickLook

    /// Spacebar: toggle the shared QuickLook panel for the Active selection. Open
    /// → close; closed with a non-empty selection → open. Driven directly (no
    /// responder-chain plumbing).
    private func togglePreview() {
        let panel = QLPreviewPanel.shared()!
        if QLPreviewPanel.sharedPreviewPanelExists() && panel.isVisible {
            panel.orderOut(nil)
            return
        }
        let urls = activeModel.selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        quickLook.urls = urls
        panel.dataSource = quickLook
        panel.makeKeyAndOrderFront(nil)
        panel.reloadData()
    }

    // MARK: - Open (default app / navigate)

    /// Activate the Active Panel's selection (Return / double-click): a single
    /// folder navigates into it; files open in their default app (Finder
    /// behavior). A mixed selection opens the files and ignores folders.
    func openSelection() {
        let items = activeModel.selectedItems
        guard !items.isEmpty else { return }
        if items.count == 1, let only = items.first, only.isDirectory {
            activeModel.navigate(into: only)
            return
        }
        for item in items where !item.isDirectory {
            NSWorkspace.shared.open(item.url)
        }
    }

    // MARK: - Finder tags

    private func beginTagging() {
        guard !activeModel.selectedItems.isEmpty else { return }
        tagging = true
    }

    /// Custom (non-built-in) tags already in use across either panel, so the
    /// picker can offer them for re-applying ("pick from the list"). Full
    /// integration with Finder's undocumented system tag store is a follow-up;
    /// this surfaces tags actually present on disk, which is robust.
    var customTagsInUse: [FinderTag] {
        let standardNames = Set(FinderTag.standard.map(\.name))
        var seen = Set<String>()
        var result: [FinderTag] = []
        for tag in left.availableTags + right.availableTags
        where !standardNames.contains(tag.name) && seen.insert(tag.name).inserted {
            result.append(tag)
        }
        return result
    }

    /// Toggle a tag across the Active selection: remove it if every selected item
    /// already has it, otherwise add it to all. One undoable `SetTagsOperation`.
    func toggleTag(_ tag: FinderTag) {
        let items = activeModel.selectedItems
        guard !items.isEmpty else { return }
        let onAll = items.allSatisfy { $0.tags.contains { $0.name == tag.name } }
        let targets: [(url: URL, newTags: [FinderTag])] = items.map { item in
            var tags = item.tags.filter { $0.name != tag.name } // drop existing copy first
            if !onAll { tags.append(tag) }                       // add unless removing
            return (item.url, tags)
        }
        let op = SetTagsOperation(targets: targets)
        coordinator.run(op) { [weak self] in self?.refreshBoth() }
    }

    // MARK: - Batch rename

    private func beginRename() {
        let items = activeModel.selectedItems
        guard !items.isEmpty else { return }
        renaming = RenameRequest(items: items, directory: activeModel.directory)
    }

    /// Apply the sheet's computed new names as one undoable `RenameOperation`.
    func commitRename(_ request: RenameRequest, newNames: [String]) {
        let renames: [(from: URL, to: URL)] = zip(request.items, newNames).compactMap { item, name in
            guard name != item.name, !name.isEmpty else { return nil } // skip unchanged
            return (from: item.url, to: request.directory.appendingPathComponent(name))
        }
        renaming = nil
        guard !renames.isEmpty else { return }
        let op = RenameOperation(renames: renames)
        // Refresh BOTH panels: when they show the same directory, the inactive
        // one would otherwise keep a stale listing until the next ⌘Z/redo.
        coordinator.run(op) { [weak self] in self?.refreshBoth() }
    }

    // MARK: - Drag & drop (routed through the same write Operations)

    /// Handle file URLs dropped on `panel`. `targetFolder` is a folder row the
    /// user dropped onto (drop into it); otherwise the drop targets the panel's
    /// current directory. Defaults to copy (safe + undoable).
    func handleDrop(_ urls: [URL], on panel: PanelModel, targetFolder: FileItem?) {
        let destination = targetFolder?.url ?? panel.directory
        // Ignore a no-op drop into the same directory the items already live in.
        let sources = urls.filter { $0.deletingLastPathComponent() != destination }
        write(.copy, sources: sources, into: destination, refresh: panel)
    }

    // MARK: - Clipboard (real macOS pasteboard, file URLs)

    private func clipboardCopy() {
        let urls = activeModel.selectionURLs
        guard !urls.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(urls as [NSURL])
    }

    private func clipboardURLs() -> [URL] {
        NSPasteboard.general.readObjects(forClasses: [NSURL.self]) as? [URL] ?? []
    }

    // MARK: - Copy / Move (collision-checked)

    /// Run a copy/move into `directory`, detecting collisions first. With no
    /// collisions it runs immediately; otherwise it pauses for the dialog.
    /// `refresh` is the Panel to re-list when the write finishes.
    private func write(_ kind: PendingWrite.Kind, sources: [URL], into directory: URL, refresh: PanelModel) {
        guard !sources.isEmpty else { return }
        let collisions = detectCollisions(sources: sources, destinationDirectory: directory)
        if collisions.isEmpty {
            runWrite(kind, sources: sources, into: directory, resolution: .rename, refresh: refresh)
        } else {
            pendingWrite = PendingWrite(kind: kind, sources: sources,
                                        destinationDirectory: directory, refresh: refresh,
                                        collisionCount: collisions.count)
        }
    }

    func resolvePendingWrite(_ pending: PendingWrite, resolution: CollisionResolution) {
        runWrite(pending.kind, sources: pending.sources,
                 into: pending.destinationDirectory, resolution: resolution, refresh: pending.refresh)
        pendingWrite = nil
    }

    private func runWrite(_ kind: PendingWrite.Kind, sources: [URL],
                          into directory: URL, resolution: CollisionResolution, refresh: PanelModel) {
        let op: Operation
        switch kind {
        case .copy: op = CopyOperation(sources: sources, destinationDirectory: directory, resolution: resolution)
        case .move: op = MoveOperation(sources: sources, destinationDirectory: directory, resolution: resolution)
        }
        coordinator.run(op) { [weak self] in
            refresh.refresh()
            self?.refreshBoth()
        }
    }

    // MARK: - Duplicate / Trash / Create

    /// Duplicate = copy into the same directory with rename ("name 2").
    private func duplicateSelection() {
        let sources = activeModel.selectionURLs
        guard !sources.isEmpty else { return }
        let op = CopyOperation(sources: sources, destinationDirectory: activeModel.directory, resolution: .rename)
        coordinator.run(op) { [weak self] in self?.refreshBoth() }
    }

    private func trashSelection() {
        let sources = activeModel.selectionURLs
        guard !sources.isEmpty else { return }
        let op = TrashOperation(sources: sources)
        coordinator.run(op) { [weak self] in self?.refreshBoth() }
    }

    private func create(_ kind: CreateOperation.Kind) {
        let op = CreateOperation(directory: activeModel.directory, kind: kind)
        coordinator.run(op) { [weak self] in self?.refreshBoth() }
    }

    private func refreshBoth() {
        left.refresh()
        right.refresh()
    }
}
