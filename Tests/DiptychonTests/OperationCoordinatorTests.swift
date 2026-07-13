import XCTest
@testable import Diptychon

/// A no-op `Operation`: records apply/revert, never touches disk. Lets us test the
/// coordinator's settle hook in isolation, without the filesystem or the UI.
/// Qualified as `Diptychon.Operation` to avoid Foundation's `Operation` (NSOperation).
private final class FakeOperation: Diptychon.Operation {
    let title = "Fake"
    let isUndoable: Bool
    let revertError: Error?
    private(set) var applied = 0
    private(set) var reverted = 0

    init(isUndoable: Bool = true, revertError: Error? = nil) {
        self.isUndoable = isUndoable
        self.revertError = revertError
    }

    func apply(progress: @escaping (Double) -> Void) async throws { applied += 1; progress(1) }
    func revert() async throws {
        if let revertError { throw revertError }
        reverted += 1
    }
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

    func testUndoAndRedoEmitLegibleToasts() async {
        let coordinator = OperationCoordinator()
        var toasts: [String] = []
        coordinator.onUndoRedoToast = { text, _ in toasts.append(text) }

        let ran = expectation(description: "run")
        coordinator.onOperationSettled = { ran.fulfill() }
        coordinator.run(FakeOperation())
        await fulfillment(of: [ran], timeout: 1)
        XCTAssertTrue(toasts.isEmpty, "a forward op does not toast")

        let undone = expectation(description: "undo")
        coordinator.onOperationSettled = { undone.fulfill() }
        coordinator.undo()
        await fulfillment(of: [undone], timeout: 1)
        XCTAssertEqual(toasts.count, 1)
        XCTAssertTrue(toasts[0].contains("Undone") && toasts[0].contains("Fake"))

        let redone = expectation(description: "redo")
        coordinator.onOperationSettled = { redone.fulfill() }
        coordinator.redo()
        await fulfillment(of: [redone], timeout: 1)
        XCTAssertTrue(toasts.last!.contains("Redone") && toasts.last!.contains("Fake"))
    }

    func testNonUndoableUndoToastsThatItCannotBeUndone() async {
        let coordinator = OperationCoordinator()
        let ran = expectation(description: "run")
        coordinator.onOperationSettled = { ran.fulfill() }
        coordinator.run(FakeOperation(isUndoable: false))
        await fulfillment(of: [ran], timeout: 1)
        // undo() settles again synchronously; drop the hook so it can't re-fulfill
        // `ran` (a second fulfill() is an XCTest API violation and crashes the run).
        coordinator.onOperationSettled = {}

        var toast: String?
        coordinator.onUndoRedoToast = { text, _ in toast = text }
        coordinator.undo()   // non-undoable path is synchronous
        XCTAssertTrue(toast?.contains("Can’t undo") == true,
                      "an overwrite never claims it was undone")
    }

    /// Issue 52: a failed revert must never claim "Undone". The op stays on the
    /// undo stack (it IS still applied) and the toast says it couldn't be undone.
    func testFailedRevertToastsHonestlyAndKeepsOpUndoable() async {
        let coordinator = OperationCoordinator()
        let ran = expectation(description: "run")
        coordinator.onOperationSettled = { ran.fulfill() }
        coordinator.run(FakeOperation(revertError: CocoaError(.fileWriteFileExists)))
        await fulfillment(of: [ran], timeout: 1)

        var toast: String?
        coordinator.onUndoRedoToast = { text, _ in toast = text }
        let undone = expectation(description: "undo settled")
        coordinator.onOperationSettled = { undone.fulfill() }
        coordinator.undo()
        await fulfillment(of: [undone], timeout: 1)

        XCTAssertTrue(toast?.contains("Couldn’t undo") == true,
                      "a failed revert must not toast 'Undone', got: \(toast ?? "nil")")
        XCTAssertTrue(coordinator.canUndo, "the still-applied op stays undoable")
        XCTAssertFalse(coordinator.canRedo, "a failed undo is not a redoable undo")
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
