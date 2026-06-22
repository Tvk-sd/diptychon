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

    /// Regression for the "only one panel refreshed after rename" bug: when both
    /// panels show the SAME directory, a batch rename in the active (left) panel
    /// must also refresh the inactive (right) panel — not leave it stale until the
    /// next ⌘Z/redo. (Fix: `commitRename` → `refreshBoth()`.)
    func testRenameRefreshesBothPanelsOnSameDir() throws {
        // Fixture: a throwaway dir with two files; both panels open it via env.
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("dipt-uitest-\(UUID().uuidString)")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        for name in ["alpha.txt", "beta.txt"] {
            fm.createFile(atPath: dir.appendingPathComponent(name).path, contents: Data())
        }
        addTeardownBlock { try? fm.removeItem(at: dir) }

        let app = XCUIApplication()
        app.launchEnvironment["DIPTYCHON_DIR"] = dir.path
        app.launch()

        let leftTable = app.tables.element(boundBy: 0)
        let rightTable = app.tables.element(boundBy: 1)
        XCTAssertTrue(rightTable.waitForExistence(timeout: 10), "Expected two panels")

        // Both panels start on the same directory, showing the original name.
        XCTAssertTrue(leftTable.staticTexts["alpha.txt"].waitForExistence(timeout: 5))
        XCTAssertTrue(rightTable.staticTexts["alpha.txt"].waitForExistence(timeout: 5))

        // Select alpha.txt in the active (left) panel, open batch rename (⌘R).
        leftTable.staticTexts["alpha.txt"].click()
        app.typeKey("r", modifierFlags: .command)

        // Replace "alpha" -> "gamma" and commit. (A genuinely new name — a
        // case-only change would trip the collision guard on case-insensitive
        // APFS, which is a separate concern from the refresh behavior tested here.)
        let find = app.textFields["Find"]
        XCTAssertTrue(find.waitForExistence(timeout: 5), "Rename sheet should open on ⌘R")
        find.click()
        find.typeText("alpha")
        let replaceWith = app.textFields["Replace with"]
        replaceWith.click()
        replaceWith.typeText("gamma")
        app.buttons["Rename"].click()

        // Active panel updates...
        XCTAssertTrue(
            leftTable.staticTexts["gamma.txt"].waitForExistence(timeout: 5),
            "Active panel should show the renamed file"
        )
        // ...and the INACTIVE panel showing the same directory must too (the bug).
        XCTAssertTrue(
            rightTable.staticTexts["gamma.txt"].waitForExistence(timeout: 5),
            "Inactive panel on the same directory must refresh after rename"
        )
    }
}
