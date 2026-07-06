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
                                        directory: folder, home: home)
        XCTAssertEqual(d?.query, "digital")   // Search text drives the walk
        XCTAssertEqual(d?.root, home)         // …rooted globally at Home
    }

    func testFilterScopesToCurrentFolderWhenNoSearch() {
        let d = PanelModel.searchDriver(searchQuery: "  ", filter: "invoice",
                                        directory: folder, home: home)
        XCTAssertEqual(d?.query, "invoice")
        XCTAssertEqual(d?.root, folder)       // scoped to the current folder
    }

    func testBothEmptyMeansNoWalk() {
        XCTAssertNil(PanelModel.searchDriver(searchQuery: "", filter: "   ",
                                             directory: folder, home: home))
    }
}
