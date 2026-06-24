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

    /// Issue 15: ⇧⌘G opens Go to Folder; typing a path navigates the Active Panel.
    func testGoToFolderNavigates() throws {
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("dipt-goto-\(UUID().uuidString)")
        let sub = dir.appendingPathComponent("sub")
        try fm.createDirectory(at: sub, withIntermediateDirectories: true)
        fm.createFile(atPath: sub.appendingPathComponent("inside.txt").path, contents: Data())
        addTeardownBlock { try? fm.removeItem(at: dir) }

        let app = XCUIApplication()
        app.launchEnvironment["DIPTYCHON_DIR"] = dir.path
        app.launch()

        let leftTable = app.tables.element(boundBy: 0)
        XCTAssertTrue(leftTable.staticTexts["sub"].waitForExistence(timeout: 10))

        // Focus the table (not the Filter field) so the ⇧⌘G shortcut is handled.
        leftTable.staticTexts["sub"].click()
        app.typeKey("g", modifierFlags: [.command, .shift])
        let field = app.textFields["goto-path"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Go to Folder opens on ⇧⌘G")
        field.click()
        field.typeKey("a", modifierFlags: .command)      // select the pre-filled path
        field.typeText(sub.path + "\n")                  // replace + submit

        XCTAssertTrue(leftTable.staticTexts["inside.txt"].waitForExistence(timeout: 5),
                      "Panel should navigate to the typed folder")
    }

    /// Issue 13: the toolbar button hides and restores the right file panel
    /// (two tables ↔ one), and the restored panel keeps its directory.
    func testToggleRightPanel() throws {
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("dipt-split-\(UUID().uuidString)")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        fm.createFile(atPath: dir.appendingPathComponent("x.txt").path, contents: Data())
        addTeardownBlock { try? fm.removeItem(at: dir) }

        let app = XCUIApplication()
        app.launchEnvironment["DIPTYCHON_DIR"] = dir.path
        // Force a known starting state (the setting persists across runs).
        app.launchArguments += ["-rightPanelVisible", "YES"]
        app.launch()

        XCTAssertTrue(app.tables.element(boundBy: 1).waitForExistence(timeout: 10))
        XCTAssertEqual(app.tables.count, 2, "Both panels visible by default")

        let toggle = app.buttons["toggle-right-panel"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.click()
        // Right panel hidden → only the left table remains.
        XCTAssertTrue(waitFor { app.tables.count == 1 }, "Right panel should hide")

        toggle.click()
        // Restored → two tables again, both still listing the directory.
        XCTAssertTrue(waitFor { app.tables.count == 2 }, "Right panel should restore")
        XCTAssertTrue(app.tables.element(boundBy: 1).staticTexts["x.txt"].waitForExistence(timeout: 5),
                      "Restored panel keeps its directory")
    }

    /// Poll a condition until true or timeout (for async UI state changes).
    private func waitFor(timeout: TimeInterval = 5, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            usleep(100_000)
        }
        return condition()
    }

    /// Issue 14: the inline preview pane reacts to the Active Panel's selection —
    /// placeholder when nothing is selected, metadata once a file is picked.
    func testPreviewPaneShowsSelectedFile() throws {
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("dipt-preview-\(UUID().uuidString)")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        fm.createFile(atPath: dir.appendingPathComponent("doc.txt").path, contents: Data("hi".utf8))
        addTeardownBlock { try? fm.removeItem(at: dir) }

        let app = XCUIApplication()
        app.launchEnvironment["DIPTYCHON_DIR"] = dir.path
        // Force the pane on regardless of the persisted default (argument domain
        // overrides UserDefaults).
        app.launchArguments += ["-previewVisible", "YES"]
        app.launch()

        let leftTable = app.tables.element(boundBy: 0)
        XCTAssertTrue(leftTable.staticTexts["doc.txt"].waitForExistence(timeout: 10))
        // Nothing selected yet → placeholder.
        XCTAssertTrue(app.staticTexts["No Selection"].waitForExistence(timeout: 5),
                      "Preview pane should start with the no-selection placeholder")

        // Select the file → the pane swaps to metadata (the placeholder is gone).
        leftTable.staticTexts["doc.txt"].click()
        XCTAssertTrue(app.staticTexts["Kind"].waitForExistence(timeout: 5),
                      "Preview pane should show metadata for the selected file")
        XCTAssertFalse(app.staticTexts["No Selection"].exists,
                       "Placeholder should be replaced once a file is selected")
    }

    /// Issue 16: the sidebar toggles (⌃⌘S / toolbar) and clicking a Place
    /// navigates the Active Panel. Navigation is verified by the temp dir's marker
    /// file disappearing after navigating to `/Applications` (not TCC-protected,
    /// unlike Home/Desktop which can hang an XCUITest on a privacy prompt).
    func testSidebarToggleAndNavigate() throws {
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("dipt-sidebar-\(UUID().uuidString)")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let marker = "marker-\(UUID().uuidString).txt"
        fm.createFile(atPath: dir.appendingPathComponent(marker).path, contents: Data())
        addTeardownBlock { try? fm.removeItem(at: dir) }

        let app = XCUIApplication()
        app.launchEnvironment["DIPTYCHON_DIR"] = dir.path
        app.launchArguments += ["-sidebarVisible", "YES"]   // known starting state
        app.launch()

        let leftTable = app.tables.element(boundBy: 0)
        XCTAssertTrue(leftTable.staticTexts[marker].waitForExistence(timeout: 10))

        // Sidebar visible → its section header shows.
        XCTAssertTrue(app.staticTexts["PLACES"].waitForExistence(timeout: 5), "Sidebar should be visible")

        let toggle = app.buttons["toggle-sidebar"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.click()
        XCTAssertTrue(waitFor { !app.staticTexts["PLACES"].exists }, "Sidebar should hide")
        toggle.click()
        XCTAssertTrue(waitFor { app.staticTexts["PLACES"].exists }, "Sidebar should restore")

        // Clicking a Place navigates the Active Panel away from the temp dir.
        app.buttons["Applications"].firstMatch.click()
        XCTAssertTrue(waitFor { !leftTable.staticTexts[marker].exists },
                      "Clicking a Place should navigate the Active Panel")
    }

    /// Issue 16 slice 2: pin a folder via its context menu → it appears in the
    /// sidebar's Pinned section → clicking it navigates the Active Panel → removing
    /// it (via context menu) makes it disappear. The remove also cleans up the
    /// persisted pin so the test doesn't leave junk in real prefs.
    func testPinFolderAppearsNavigatesAndRemoves() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("dipt-pin-\(UUID().uuidString)")
        let folderName = "target-\(UUID().uuidString)"
        let target = root.appendingPathComponent(folderName)
        try fm.createDirectory(at: target, withIntermediateDirectories: true)
        fm.createFile(atPath: target.appendingPathComponent("inner.txt").path, contents: Data())
        addTeardownBlock { try? fm.removeItem(at: root) }

        let app = XCUIApplication()
        app.launchEnvironment["DIPTYCHON_DIR"] = root.path
        app.launchArguments += ["-sidebarVisible", "YES"]
        app.launch()

        let leftTable = app.tables.element(boundBy: 0)
        XCTAssertTrue(leftTable.staticTexts[folderName].waitForExistence(timeout: 10))

        // Right-click the folder → "Add to Sidebar".
        leftTable.staticTexts[folderName].rightClick()
        let pinItem = app.menuItems["Add to Sidebar"]
        XCTAssertTrue(pinItem.waitForExistence(timeout: 5), "Folder menu should offer Add to Sidebar")
        pinItem.click()

        // It appears in the sidebar's Pinned section (distinct a11y id, since the
        // same name also exists as a file-list row).
        let pinnedRow = app.buttons["pinned:\(folderName)"]
        XCTAssertTrue(pinnedRow.waitForExistence(timeout: 5), "Pinned folder should appear in the sidebar")

        // Clicking it navigates the Active Panel into the folder.
        pinnedRow.click()
        XCTAssertTrue(leftTable.staticTexts["inner.txt"].waitForExistence(timeout: 5),
                      "Clicking a pin should navigate the Active Panel")

        // Remove via context menu → disappears (and clears the persisted pin).
        pinnedRow.rightClick()
        let removeItem = app.menuItems["Remove from Sidebar"]
        XCTAssertTrue(removeItem.waitForExistence(timeout: 5))
        removeItem.click()
        XCTAssertTrue(waitFor { !app.buttons["pinned:\(folderName)"].exists },
                      "Removed pin should disappear from the sidebar")
    }

    /// Issue 16 slice 3: a pinned folder that no longer exists degrades
    /// gracefully — it shows as "missing" (greyed, distinct a11y id), clicking it
    /// does not navigate, and the app stays responsive (no crash). Still removable.
    func testMissingPinnedFolderDegradesGracefully() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("dipt-missing-\(UUID().uuidString)")
        let folderName = "victim-\(UUID().uuidString)"
        let victim = root.appendingPathComponent(folderName)
        try fm.createDirectory(at: victim, withIntermediateDirectories: true)
        let marker = "marker-\(UUID().uuidString).txt"
        fm.createFile(atPath: root.appendingPathComponent(marker).path, contents: Data())
        addTeardownBlock { try? fm.removeItem(at: root) }

        let app = XCUIApplication()
        app.launchEnvironment["DIPTYCHON_DIR"] = root.path
        app.launchArguments += ["-sidebarVisible", "YES"]
        app.launch()

        let leftTable = app.tables.element(boundBy: 0)
        XCTAssertTrue(leftTable.staticTexts[folderName].waitForExistence(timeout: 10))

        // Pin the folder.
        leftTable.staticTexts[folderName].rightClick()
        let pinItem = app.menuItems["Add to Sidebar"]
        XCTAssertTrue(pinItem.waitForExistence(timeout: 5))
        pinItem.click()
        XCTAssertTrue(app.buttons["pinned:\(folderName)"].waitForExistence(timeout: 5))

        // Delete it on disk, then force the sidebar to re-render (toggle off/on).
        try fm.removeItem(at: victim)
        let toggle = app.buttons["toggle-sidebar"]
        toggle.click()
        XCTAssertTrue(waitFor { !app.staticTexts["PLACES"].exists })
        toggle.click()
        XCTAssertTrue(waitFor { app.staticTexts["PLACES"].exists })

        // The pin now shows as missing rather than crashing.
        let missingRow = app.buttons["pinned-missing:\(folderName)"]
        XCTAssertTrue(missingRow.waitForExistence(timeout: 5), "Deleted pin should show as missing")

        // Clicking it is a no-op: the Active Panel stays put (marker still listed).
        missingRow.click()
        XCTAssertTrue(leftTable.staticTexts[marker].waitForExistence(timeout: 3),
                      "Clicking a missing pin should not navigate")
        XCTAssertTrue(app.staticTexts["PLACES"].exists, "App should remain responsive")

        // Still removable (also clears the stale persisted pin).
        missingRow.rightClick()
        let removeItem = app.menuItems["Remove from Sidebar"]
        XCTAssertTrue(removeItem.waitForExistence(timeout: 5))
        removeItem.click()
        XCTAssertTrue(waitFor { !app.buttons["pinned-missing:\(folderName)"].exists })
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
