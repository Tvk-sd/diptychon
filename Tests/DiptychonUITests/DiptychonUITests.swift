import XCTest

/// First XCUITest smoke test — the payoff of the Xcode migration. With a real
/// Xcode project the agent can launch the app and assert UI state directly,
/// instead of the "you click, I read /tmp/dipt.log" loop used for issues 01–07.
final class DiptychonUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launch the app and assert the dual-panel workspace is on screen: a window
    /// exists and it contains exactly two file lists (the left + right Panels,
    /// each an NSTableView → XCUIElement `table`).
    func testLaunchesWithTwoPanels() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.windows.firstMatch.waitForExistence(timeout: 10),
            "Expected a Diptychon window after launch"
        )

        // Both Panels render their file list as an NSTableView.
        let tables = app.tables
        XCTAssertTrue(
            tables.element(boundBy: 1).waitForExistence(timeout: 5),
            "Expected a second file-list table (the right Panel)"
        )
        XCTAssertEqual(tables.count, 2, "Expected exactly two Panels (two tables)")
    }
}
