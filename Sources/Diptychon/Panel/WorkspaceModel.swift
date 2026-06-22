import SwiftUI
import AppKit
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

    var active: Side = .left
    var pendingWrite: PendingWrite?
    var renaming: RenameRequest?

    init() {
        left = PanelModel(directory: .startDirectory)
        right = PanelModel(directory: .startDirectory)
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
        case .copyToInactive: write(.copy, sources: activeModel.selectionURLs, into: inactiveModel.directory, refresh: inactiveModel)
        case .undo: coordinator.undo(onFinish: refreshBoth)
        case .redo: coordinator.redo(onFinish: refreshBoth)
        case .goUp: activeModel.navigateUp()
        case .switchPanel: active = (active == .left) ? .right : .left
        case .clipboardCopy: clipboardCopy()
        case .paste: write(.copy, sources: clipboardURLs(), into: activeModel.directory, refresh: activeModel)
        case .pasteMove: write(.move, sources: clipboardURLs(), into: activeModel.directory, refresh: activeModel)
        case .trash: trashSelection()
        case .duplicate: duplicateSelection()
        case .newFolder: create(.folder)
        case .newFile: create(.file)
        case .rename: beginRename()
        }
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
