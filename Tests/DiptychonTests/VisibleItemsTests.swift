import XCTest
@testable import Diptychon

/// `PanelModel.compileVisible` — the pure base→filter→sort pipeline behind a Panel's
/// rows. `applyFilters` is covered by `PanelFilterTests`; this pins the base-set
/// selection (search vs loaded) and sort that wrap it.
@MainActor
final class VisibleItemsTests: XCTestCase {

    private func item(_ name: String) -> FileItem {
        FileItem(url: URL(fileURLWithPath: "/x/\(name)"), name: name, size: 1,
                 modificationDate: nil, isDirectory: false, tags: [])
    }
    private let byName = [KeyPathComparator(\FileItem.name)]

    func testNotSearchingUsesLoadedSorted() {
        let out = PanelModel.compileVisible(
            loaded: [item("b"), item("a")], searchResults: [item("zzz")],
            isSearching: false, filter: "", tagName: nil, sort: byName)
        XCTAssertEqual(out.map(\.name), ["a", "b"], "uses loaded items, sorted by name")
    }

    func testSearchingKeepsRelevanceOrderNotColumnSort() {
        // Search results arrive pre-ranked by relevance; compileVisible must NOT
        // re-sort them by the column comparator, or the best match would sink.
        let out = PanelModel.compileVisible(
            loaded: [item("a")], searchResults: [item("hit2"), item("hit1")],
            isSearching: true, filter: "", tagName: nil, sort: byName)
        XCTAssertEqual(out.map(\.name), ["hit2", "hit1"], "preserves the walk's relevance order")
    }

    func testFilterAppliesOverTheChosenBase() {
        let out = PanelModel.compileVisible(
            loaded: [item("apple"), item("banana"), item("apricot")], searchResults: [],
            isSearching: false, filter: "ap", tagName: nil, sort: byName)
        XCTAssertEqual(out.map(\.name), ["apple", "apricot"])
    }
}
