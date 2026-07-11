import XCTest
@testable import Diptychon

/// Issue 20: the add surfaces feed the shared staging set, and the right auxiliary
/// pane shows preview XOR staging. The list UI is verified manually; this covers the
/// workspace-level routing and the mutually-exclusive pane state.
@MainActor
final class WorkspaceStagingTests: XCTestCase {

    private let a = URL(fileURLWithPath: "/tmp/staging-a.txt")
    private let b = URL(fileURLWithPath: "/tmp/staging-b.txt")

    /// A workspace with a known right-pane baseline (the live default comes from
    /// persisted prefs, which we don't want these tests to depend on). The staged
    /// set is persisted too (issue 41) and restored by `WorkspaceModel()`, so it
    /// must be reset the same way — otherwise the developer's real staged items
    /// leak into these assertions (bit us 2026-07-11 with a non-empty live set).
    private func makeModel() -> WorkspaceModel {
        let model = WorkspaceModel()
        model.rightPane = .none
        model.staging.clear()
        return model
    }

    func testAddToStagingCollectsDedupesAndRevealsPane() {
        let model = makeModel()
        model.addToStaging([a, b])
        model.addToStaging([a])   // already staged — ignored
        XCTAssertEqual(model.staging.urls, [a, b])
        XCTAssertEqual(model.rightPane, .staging, "adding reveals the staging pane")
    }

    func testEmptyAddIsANoOp() {
        let model = makeModel()
        model.addToStaging([])
        XCTAssertTrue(model.staging.isEmpty)
        XCTAssertEqual(model.rightPane, .none, "an empty add does not pop the pane")
    }

    func testStagingFocusFollowsPaneAndDrivesOperationSource() {
        let model = makeModel()
        XCTAssertFalse(model.stagingFocused)
        XCTAssertTrue(model.operationSourceModel === model.activeModel,
                      "source is the active file panel until staging is focused")

        model.toggleStaging()   // open staging → it takes operation focus
        XCTAssertTrue(model.stagingFocused)
        XCTAssertTrue(model.operationSourceModel === model.stagingPanel,
                      "a focused Staging pane is the operation source")

        model.stagingFocused = false   // simulate clicking back into a file panel
        XCTAssertTrue(model.operationSourceModel === model.activeModel)

        model.toggleStaging()   // hide staging → focus returns to file panels
        XCTAssertFalse(model.stagingFocused)
    }

    func testDeleteUnstagesTheStagingSelection() {
        let model = makeModel()
        model.addToStaging([a, b])        // reveals + focuses staging
        model.stagingPanel.selection = [a]
        model.perform(.removeFromStaging)
        XCTAssertEqual(model.staging.urls, [b], "⌫ in staging unstages, leaving the rest")
    }

    func testDeleteDoesNothingWhenStagingNotFocused() {
        let model = makeModel()
        model.addToStaging([a, b])
        model.stagingFocused = false      // focus is on a file panel
        model.stagingPanel.selection = [a]
        model.perform(.removeFromStaging)
        XCTAssertEqual(model.staging.urls, [a, b], "no unstage unless staging holds focus")
    }

    func testRemoveFromStagingAndClearAreNonDestructiveToTheSet() {
        let model = makeModel()
        model.addToStaging([a, b])
        model.removeFromStaging([a])
        XCTAssertEqual(model.staging.urls, [b], "remove drops just the named item")
        model.clearStaging()
        XCTAssertTrue(model.staging.isEmpty, "clear empties the set")
    }

    func testMissingStagedItemsAreExcludedFromOperationSources() async throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("stg-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let present = dir.appendingPathComponent("here.txt")
        try Data("x".utf8).write(to: present)
        let gone = dir.appendingPathComponent("gone.txt")   // never created → missing

        let model = makeModel()
        model.addToStaging([present, gone])   // reveals + focuses staging
        // Wait for the staging pane to list both rows.
        let deadline = Date().addingTimeInterval(2)
        while model.stagingPanel.visibleItems.count < 2, Date() < deadline {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        model.stagingPanel.selection = [present, gone]
        XCTAssertEqual(model.operationSourceURLs, [present],
                       "a missing staged item is not a copy/move/trash/tag source")
    }

    func testPreviewAndStagingShareTheRightPaneExclusively() {
        let model = makeModel()
        model.togglePreviewPane()
        XCTAssertEqual(model.rightPane, .preview)
        model.toggleStaging()
        XCTAssertEqual(model.rightPane, .staging, "staging off-swaps preview")
        model.togglePreviewPane()
        XCTAssertEqual(model.rightPane, .preview, "preview off-swaps staging")
        model.togglePreviewPane()
        XCTAssertEqual(model.rightPane, .none, "toggling the shown pane hides it")
    }
}
