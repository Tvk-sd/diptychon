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

    /// A copy paused on the collision-resolution step.
    struct PendingCopy: Identifiable {
        let id = UUID()
        let sources: [URL]
        let destination: PanelModel
        let collisionCount: Int
    }

    let left: PanelModel
    let right: PanelModel
    let coordinator = OperationCoordinator()

    var active: Side = .left
    var pendingCopy: PendingCopy?

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
        case .copyToInactive: copyToInactive()
        case .undo: coordinator.undo(onFinish: refreshBoth)
        case .redo: coordinator.redo(onFinish: refreshBoth)
        case .goUp: activeModel.navigateUp()
        case .switchPanel: active = (active == .left) ? .right : .left
        }
    }

    /// Commander gesture: copy the Active Panel selection into the Inactive Panel.
    private func copyToInactive() {
        let sources = activeModel.selectionURLs
        guard !sources.isEmpty else { return }
        let destination = inactiveModel
        let collisions = detectCollisions(sources: sources,
                                          destinationDirectory: destination.directory)
        if collisions.isEmpty {
            runCopy(sources: sources, destination: destination, resolution: .rename)
        } else {
            pendingCopy = PendingCopy(sources: sources,
                                      destination: destination,
                                      collisionCount: collisions.count)
        }
    }

    func startCopy(_ pending: PendingCopy, resolution: CollisionResolution) {
        runCopy(sources: pending.sources, destination: pending.destination, resolution: resolution)
        pendingCopy = nil
    }

    private func runCopy(sources: [URL], destination: PanelModel, resolution: CollisionResolution) {
        let op = CopyOperation(sources: sources,
                               destinationDirectory: destination.directory,
                               resolution: resolution)
        coordinator.run(op) { destination.refresh() }
    }

    private func refreshBoth() {
        left.refresh()
        right.refresh()
    }
}
