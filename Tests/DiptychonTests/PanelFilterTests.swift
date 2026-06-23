import XCTest
@testable import Diptychon

/// Slice 4 (AC4): the Active Panel can be filtered to a single tag. The filter
/// logic is factored into the pure `PanelModel.applyFilters` so it's testable
/// without an async directory load. `@MainActor` because the symbol lives on a
/// `@MainActor` model.
@MainActor
final class PanelFilterTests: XCTestCase {
    private func item(_ name: String, tags: [FinderTag] = []) -> FileItem {
        FileItem(url: URL(fileURLWithPath: "/tmp/\(name)"), name: name,
                 size: 0, modificationDate: nil, isDirectory: false, tags: tags)
    }

    private let red = FinderTag(name: "Red", color: .red)
    private let blue = FinderTag(name: "Blue", color: .blue)

    func testNoTagFilterReturnsAll() {
        let items = [item("a.txt", tags: [red]), item("b.txt")]
        let out = PanelModel.applyFilters(items, text: "", tagName: nil)
        XCTAssertEqual(out.map(\.name), ["a.txt", "b.txt"])
    }

    func testTagFilterKeepsOnlyMatching() {
        let items = [item("a.txt", tags: [red]), item("b.txt", tags: [blue]), item("c.txt")]
        let out = PanelModel.applyFilters(items, text: "", tagName: "Red")
        XCTAssertEqual(out.map(\.name), ["a.txt"])
    }

    func testTagFilterMatchesAnyOfMultipleTags() {
        let items = [item("a.txt", tags: [red, blue]), item("b.txt", tags: [blue])]
        let out = PanelModel.applyFilters(items, text: "", tagName: "Red")
        XCTAssertEqual(out.map(\.name), ["a.txt"])
    }

    func testTextAndTagFilterCombine() {
        let items = [
            item("report-red.txt", tags: [red]),
            item("notes-red.txt", tags: [red]),
            item("report-blue.txt", tags: [blue]),
        ]
        let out = PanelModel.applyFilters(items, text: "report", tagName: "Red")
        XCTAssertEqual(out.map(\.name), ["report-red.txt"])
    }

    func testUnknownTagFilterReturnsEmpty() {
        let items = [item("a.txt", tags: [red])]
        let out = PanelModel.applyFilters(items, text: "", tagName: "Green")
        XCTAssertTrue(out.isEmpty)
    }
}
