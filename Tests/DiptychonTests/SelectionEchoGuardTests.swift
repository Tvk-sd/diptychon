import XCTest
@testable import Diptychon

/// The AppKit↔SwiftUI selection echo rule, tested without a live `NSTableView`.
/// This is the logic that, when wrong, causes selection thrash / wiped selection.
final class SelectionEchoGuardTests: XCTestCase {

    private func ids(_ names: String...) -> Set<FileItem.ID> {
        Set(names.map { URL(fileURLWithPath: "/x/\($0)") })
    }

    // MARK: table → binding (captureFromTable)

    func testCaptureWhenIdlePublishesIds() {
        var g = SelectionEchoGuard()
        XCTAssertEqual(g.captureFromTable(ids("a", "b")), ids("a", "b"))
    }

    func testCaptureWhileApplyingIsSuppressed() {
        var g = SelectionEchoGuard()
        g.beginApply()
        XCTAssertNil(g.captureFromTable(ids("a")), "our own programmatic selection must not echo to the binding")
        g.endApply()
        XCTAssertEqual(g.captureFromTable(ids("a")), ids("a"), "after the apply window, real clicks publish again")
    }

    // MARK: binding → table (shouldApply)

    func testApplyExternalChange() {
        var g = SelectionEchoGuard()
        XCTAssertTrue(g.shouldApply(ids("a")), "a fresh external selection applies to the table")
    }

    func testEchoOfWhatTablePublishedIsSkipped() {
        var g = SelectionEchoGuard()
        _ = g.captureFromTable(ids("a", "b"))           // table published a,b
        XCTAssertFalse(g.shouldApply(ids("a", "b")), "the binding echo of that publish is skipped")
    }

    func testExternalChangeAfterPublishApplies() {
        var g = SelectionEchoGuard()
        _ = g.captureFromTable(ids("a"))                // table published a
        XCTAssertTrue(g.shouldApply(ids("b")), "a different (external) value still applies")
        XCTAssertFalse(g.shouldApply(ids("b")), "...and its own echo is then skipped")
    }

    // MARK: reentrancy flag

    func testBeginEndToggleIsApplying() {
        var g = SelectionEchoGuard()
        XCTAssertFalse(g.isApplying)
        g.beginApply(); XCTAssertTrue(g.isApplying)
        g.endApply();   XCTAssertFalse(g.isApplying)
    }
}
