import XCTest
@testable import Diptychon

/// Issue 97: a search inside the column browser is drawn as the detailed table; the
/// chosen display mode itself never changes, so columns return once the query clears.
@MainActor
final class RenderedModeTests: XCTestCase {
    private func model() -> PanelModel { PanelModel(directory: URL(fileURLWithPath: "/")) }

    func testColumnsRenderAsTableWhileSearching() {
        let m = model()
        m.displayMode = .columns
        XCTAssertEqual(m.renderedMode, .columns)
        m.searchQuery = "digital"
        XCTAssertTrue(m.isSearching)
        XCTAssertEqual(m.renderedMode, .table, "results need the flat list, not the column chain")
        XCTAssertEqual(m.displayMode, .columns, "the user's choice is untouched")
        m.searchQuery = ""
        XCTAssertEqual(m.renderedMode, .columns, "columns come back as soon as the search clears")
    }

    func testOtherModesAreUnaffectedBySearch() {
        let m = model()
        m.displayMode = .brief(columns: 3)
        m.searchQuery = "digital"
        XCTAssertEqual(m.renderedMode, .brief(columns: 3))
        m.displayMode = .table
        XCTAssertEqual(m.renderedMode, .table)
    }
}
