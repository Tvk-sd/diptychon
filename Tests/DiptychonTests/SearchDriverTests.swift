import XCTest
@testable import Diptychon

/// The scope decision behind the two search fields (Slice 2): global **Search**
/// roots at Home; **Filter** roots at the current folder; neither ⇒ no walk.
@MainActor
final class SearchDriverTests: XCTestCase {
    private let home = URL(fileURLWithPath: "/Users/me")
    private let folder = URL(fileURLWithPath: "/Users/me/Projects/app")

    func testSearchWinsAndRootsAtHome() {
        let d = PanelModel.searchDriver(searchQuery: "digital", filter: "cv",
                                        directory: folder, home: home, filterRecurses: true)
        XCTAssertEqual(d?.query, "digital")   // Search text drives the walk
        XCTAssertEqual(d?.root, home)         // …rooted globally at Home
    }

    func testFilterScopesToCurrentFolderWhenRecursing() {
        let d = PanelModel.searchDriver(searchQuery: "  ", filter: "invoice",
                                        directory: folder, home: home, filterRecurses: true)
        XCTAssertEqual(d?.query, "invoice")
        XCTAssertEqual(d?.root, folder)       // scoped to the current folder
    }

    func testFilterDoesNotWalkWhenPaneDoesNotRecurse() {
        // Virtual sources (staging) narrow in-memory — the Filter must not drive a
        // filesystem walk of their nominal directory.
        XCTAssertNil(PanelModel.searchDriver(searchQuery: "", filter: "invoice",
                                             directory: folder, home: home, filterRecurses: false))
    }

    func testBothEmptyMeansNoWalk() {
        XCTAssertNil(PanelModel.searchDriver(searchQuery: "", filter: "   ",
                                             directory: folder, home: home, filterRecurses: true))
    }
}
