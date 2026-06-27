import XCTest
@testable import Diptychon

/// A no-op `Operation`: records apply/revert, never touches disk. Lets us test the
/// coordinator's settle hook in isolation, without the filesystem or the UI.
/// Qualified as `Diptychon.Operation` to avoid Foundation's `Operation` (NSOperation).
private final class FakeOperation: Diptychon.Operation {
    let title = "Fake"
    let isUndoable: Bool
    private(set) var applied = 0
    private(set) var reverted = 0

    init(isUndoable: Bool = true) { self.isUndoable = isUndoable }

    func apply(progress: @escaping (Double) -> Void) async throws { applied += 1; progress(1) }
    func revert() async throws { reverted += 1 }
}

/// `onOperationSettled` is the single point that tells the UI to re-list after an
/// Operation. These tests pin down *when* it fires — the wiring that used to live
/// in nine scattered closures inside `WorkspaceModel`, untestable without the app.
@MainActor
final class OperationCoordinatorTests: XCTestCase {

    func testSettleHookFiresAfterRun() async {
        let coordinator = OperationCoordinator()
        let settled = expectation(description: "settled after run")
        coordinator.onOperationSettled = { settled.fulfill() }

        coordinator.run(FakeOperation())

        await fulfillment(of: [settled], timeout: 1)
        XCTAssertEqual(coordinator.undoStack.count, 1, "a successful run is pushed for undo")
    }

    func testSettleHookFiresAfterUndoThenRedo() async {
        let coordinator = OperationCoordinator()

        let ran = expectation(description: "run settled")
        coordinator.onOperationSettled = { ran.fulfill() }
        coordinator.run(FakeOperation())
        await fulfillment(of: [ran], timeout: 1)

        let undone = expectation(description: "undo settled")
        coordinator.onOperationSettled = { undone.fulfill() }
        coordinator.undo()
        await fulfillment(of: [undone], timeout: 1)
        XCTAssertTrue(coordinator.canRedo, "undo moves the Operation onto the redo stack")

        let redone = expectation(description: "redo settled")
        coordinator.onOperationSettled = { redone.fulfill() }
        coordinator.redo()
        await fulfillment(of: [redone], timeout: 1)
        XCTAssertTrue(coordinator.canUndo, "redo restores it to the undo stack")
    }

    func testEmptyUndoDoesNotFire() {
        let coordinator = OperationCoordinator()
        var count = 0
        coordinator.onOperationSettled = { count += 1 }

        coordinator.undo() // nothing on the stack

        XCTAssertEqual(count, 0, "nothing changed → no refresh")
    }

    func testEmptyRedoDoesNotFire() {
        let coordinator = OperationCoordinator()
        var count = 0
        coordinator.onOperationSettled = { count += 1 }

        coordinator.redo() // nothing to redo

        XCTAssertEqual(count, 0, "nothing changed → no refresh")
    }
}
