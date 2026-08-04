import XCTest
@testable import Diptychon

/// Issue 75: a first launch used to open both Panels on home, so the very first
/// screen was two identical lists — the one moment the two-pane idea has to land.
final class StartDirectoryTests: XCTestCase {
    /// Guards the tests below: they only mean anything when the override is absent,
    /// because `DIPTYCHON_DIR` deliberately collapses both panes onto one folder.
    private var overrideIsSet: Bool {
        ProcessInfo.processInfo.environment["DIPTYCHON_DIR"] != nil
    }

    func testSecondPaneStartsSomewhereElseThanTheFirst() throws {
        try XCTSkipIf(overrideIsSet, "DIPTYCHON_DIR collapses both panes on purpose")
        XCTAssertNotEqual(
            URL.secondPaneStartDirectory, URL.startDirectory,
            "A first launch must not open both Panels on the same folder"
        )
    }

    /// `/Applications` rather than Documents or Downloads: those are TCC-protected,
    /// and issue 77 has the app already prompting for folder access at launch. A first
    /// run that opens straight into another permission dialog is worse than two
    /// identical panels.
    func testSecondPaneStartsInAnUnprotectedDirectory() throws {
        try XCTSkipIf(overrideIsSet, "DIPTYCHON_DIR collapses both panes on purpose")
        let second = URL.secondPaneStartDirectory
        XCTAssertEqual(second.path, "/Applications")

        let protectedNames = ["Desktop", "Documents", "Downloads"]
        XCTAssertFalse(
            protectedNames.contains(second.lastPathComponent),
            "\(second.lastPathComponent) is TCC-protected — it would greet a first run with a dialog"
        )
    }

    func testSecondPaneIsReachable() throws {
        try XCTSkipIf(overrideIsSet, "DIPTYCHON_DIR collapses both panes on purpose")
        var isDirectory: ObjCBool = false
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: URL.secondPaneStartDirectory.path,
                                           isDirectory: &isDirectory),
            "The first-run folder must exist, or the right Panel opens empty"
        )
        XCTAssertTrue(isDirectory.boolValue)
    }
}
