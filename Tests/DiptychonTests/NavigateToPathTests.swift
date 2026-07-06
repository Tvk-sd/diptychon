import XCTest
@testable import Diptychon

/// `PanelModel.navigateIfPath` — pasting an absolute/`~` path into Search jumps
/// there instead of fuzzy-searching (a file lands in its containing folder).
@MainActor
final class NavigateToPathTests: XCTestCase {
    private func model() -> PanelModel { PanelModel(directory: URL(fileURLWithPath: "/")) }

    func testAbsoluteDirPathNavigates() {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        let m = model()
        XCTAssertTrue(m.navigateIfPath(tmp.path))
        XCTAssertEqual(m.directory.standardizedFileURL.path, tmp.standardizedFileURL.path)
    }

    func testFilePathLandsInContainingFolder() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("navtest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("x.txt")
        try "".write(to: file, atomically: true, encoding: .utf8)

        let m = model()
        XCTAssertTrue(m.navigateIfPath(file.path))
        XCTAssertEqual(m.directory.standardizedFileURL.path, dir.standardizedFileURL.path)
    }

    func testSettingSearchQueryToAPathNavigatesLive() {
        // The live wiring: pasting a path into Search jumps there (no Enter).
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        let m = model()
        m.searchQuery = tmp.path
        XCTAssertEqual(m.directory.standardizedFileURL.path, tmp.standardizedFileURL.path)
        XCTAssertEqual(m.searchQuery, "", "search is cleared after the jump")
    }

    func testFileJumpMarksTargetAndSelectionClearsIt() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("navtest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("x.txt")
        try "".write(to: file, atomically: true, encoding: .utf8)

        let m = model()
        m.navigateIfPath(file.path)
        XCTAssertEqual(m.highlightedTargetURL?.standardizedFileURL, file.standardizedFileURL,
                       "a file jump marks the landed-on file")

        m.selection = [file]            // any user selection dismisses the marker
        XCTAssertNil(m.highlightedTargetURL)
    }

    func testDirJumpMarksNothing() {
        let m = model()
        m.navigateIfPath(NSTemporaryDirectory())
        XCTAssertNil(m.highlightedTargetURL, "landing inside a folder has nothing to mark")
    }

    func testNonPathOrMissingPathIsNotHandled() {
        let m = model()
        XCTAssertFalse(m.navigateIfPath("digital"))                        // not a path → search
        XCTAssertFalse(m.navigateIfPath("/nope/\(UUID().uuidString)"))     // doesn't exist
    }
}
