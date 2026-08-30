import XCTest
@testable import Diptychon

/// A no-op `Operation` so the coordinator can be put into its "running" state
/// without touching the filesystem. Qualified as `Diptychon.Operation` to avoid
/// Foundation's `Operation` (NSOperation).
private final class FakeOperation: Diptychon.Operation {
    let title = "Fake"
    let isUndoable = true
    func apply(progress: @escaping (Double) -> Void) async throws { progress(1) }
    func revert() async throws {}
}

/// Issue 34, Slice 1 follow-up — the Activity pane's ✕ was a no-op during any
/// Operation: the pane was on screen because `running != nil`, and closing only
/// cleared `activityPanelPinned`, which was already `false`. Reported from real
/// use ("Activity Fenster lässt sich nicht schließen").
///
/// These pin down the dismissable-not-disabled contract: closing hides the pane
/// for the *current* op, and the *next* op brings it back.
@MainActor
final class ActivityPanelVisibilityTests: XCTestCase {

    /// A workspace with a known Activity baseline — the flags are in-memory, but
    /// `WorkspaceModel()` restores other persisted state, so assert nothing else.
    private func makeModel() -> WorkspaceModel {
        let model = WorkspaceModel()
        model.setActivityPanelVisible(false)
        model.activityPanelDismissed = false
        return model
    }

    func testRunningOperationAutoShowsThePane() {
        let model = makeModel()
        XCTAssertFalse(model.activityPanelVisible, "idle and unpinned — no pane")

        model.coordinator.run(FakeOperation())
        XCTAssertTrue(model.activityPanelVisible, "a running op surfaces the pane")
    }

    /// The reported bug: ✕ during a running op must actually close the pane.
    func testCloseDuringRunningOperationHidesThePane() {
        let model = makeModel()
        model.coordinator.run(FakeOperation())
        XCTAssertTrue(model.activityPanelVisible)

        model.setActivityPanelVisible(false)
        XCTAssertFalse(model.activityPanelVisible,
                       "✕ closes the pane even while the op keeps running")
        XCTAssertNotNil(model.coordinator.running,
                        "closing the pane does not cancel the op — non-blocking, not modal")
    }

    /// Dismissing applies to one op, not to every op from now on.
    func testNextOperationClearsTheDismissal() async {
        let model = makeModel()

        let firstSettled = expectation(description: "first op settled")
        model.coordinator.onOperationSettled = { firstSettled.fulfill() }
        model.coordinator.run(FakeOperation())
        model.setActivityPanelVisible(false)
        await fulfillment(of: [firstSettled], timeout: 1)
        XCTAssertFalse(model.activityPanelVisible, "still dismissed after the op ends")

        // Detach the hook: the op below settles after this test returns, and a
        // second `fulfill()` on a spent expectation trips XCTest.
        model.coordinator.onOperationSettled = {}
        model.coordinator.run(FakeOperation())
        XCTAssertTrue(model.activityPanelVisible, "the next op surfaces the pane again")
    }

    /// Undo runs through the same start hook, so it un-dismisses too.
    func testUndoAlsoClearsTheDismissal() async {
        let model = makeModel()

        let ran = expectation(description: "run settled")
        model.coordinator.onOperationSettled = { ran.fulfill() }
        model.coordinator.run(FakeOperation())
        model.setActivityPanelVisible(false)
        await fulfillment(of: [ran], timeout: 1)

        model.coordinator.onOperationSettled = {}   // see note in the test above
        model.coordinator.undo()
        XCTAssertTrue(model.activityPanelVisible, "undo surfaces the pane again")
    }

    /// Pinning outlives the op — the pane is a place the user can keep open.
    func testPinnedPaneSurvivesAnIdleWorkspace() async {
        let model = makeModel()
        model.setActivityPanelVisible(true)
        XCTAssertTrue(model.activityPanelVisible, "pinned open while idle")

        let settled = expectation(description: "settled")
        model.coordinator.onOperationSettled = { settled.fulfill() }
        model.coordinator.run(FakeOperation())
        await fulfillment(of: [settled], timeout: 1)

        XCTAssertTrue(model.activityPanelVisible, "an op ending does not unpin it")
    }
}
