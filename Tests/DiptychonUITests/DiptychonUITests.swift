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
        // Point both panels at a controlled temp dir rather than the user's home:
        // home can contain TCC-protected folders (Desktop/Documents/…) whose load
        // may block on a permission prompt under XCUITest, leaving panels stuck
        // "Loading…". A temp dir keeps this smoke test deterministic.
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("dipt-launch-\(UUID().uuidString)")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        fm.createFile(atPath: dir.appendingPathComponent("file.txt").path, contents: Data())
        addTeardownBlock { try? fm.removeItem(at: dir) }

        let app = XCUIApplication()
        app.launchEnvironment["DIPTYCHON_DIR"] = dir.path
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

    /// Issue 08 AC2: set a tag on the selection via the picker (⌘T), and undo it.
    /// Asserts against the file's actual `_kMDItemUserTags` xattr — which is both
    /// robust (no accessibility-tree guessing) and proof of the Finder round-trip.
    func testSetAndUndoTagViaPicker() throws {
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("dipt-uitag-\(UUID().uuidString)")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("doc.txt")
        fm.createFile(atPath: fileURL.path, contents: Data())
        addTeardownBlock { try? fm.removeItem(at: dir) }

        let app = XCUIApplication()
        app.launchEnvironment["DIPTYCHON_DIR"] = dir.path
        app.launch()

        let leftTable = app.tables.element(boundBy: 0)
        XCTAssertTrue(leftTable.staticTexts["doc.txt"].waitForExistence(timeout: 10))

        // Select the file, open the tag picker (⌘T), toggle Red on, close.
        leftTable.staticTexts["doc.txt"].click()
        app.typeKey("t", modifierFlags: .command)
        let redToggle = app.buttons["tag-Red"]
        XCTAssertTrue(redToggle.waitForExistence(timeout: 5), "Tag picker should open on ⌘T")
        // Click the rendered content (the color dot at the row's left), which is the
        // reliable hit point for XCUITest's synthetic click inside a SwiftUI sheet.
        redToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.5)).click()
        app.buttons["Done"].click()

        XCTAssertTrue(waitForTagNames(of: fileURL.path, toEqual: ["Red"]),
                      "Setting Red should write it to the file's tag xattr (Finder round-trip)")

        // Undo restores the untagged state.
        app.typeKey("z", modifierFlags: .command)
        XCTAssertTrue(waitForTagNames(of: fileURL.path, toEqual: []),
                      "Undo should remove the tag")
    }

    /// Poll the file's tag xattr (the op is async) until it matches, or time out.
    private func waitForTagNames(of path: String, toEqual expected: [String], timeout: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if tagNames(of: path) == expected { return true }
            usleep(100_000)
        } while Date() < deadline
        return tagNames(of: path) == expected
    }

    /// Tag names parsed straight from the `_kMDItemUserTags` xattr (no app module).
    private func tagNames(of path: String) -> [String] {
        let name = "com.apple.metadata:_kMDItemUserTags"
        let len = getxattr(path, name, nil, 0, 0, 0)
        guard len > 0 else { return [] }
        var data = Data(count: len)
        let read = data.withUnsafeMutableBytes { getxattr(path, name, $0.baseAddress, len, 0, 0) }
        guard read > 0,
              let arr = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String]
        else { return [] }
        return arr.map { String($0.split(separator: "\n").first ?? "") }
    }
}
