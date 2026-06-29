import XCTest
@testable import Diptychon

/// Unit tests for `FinderTag.distinctByName` — the dedup feeding the header's
/// tag-filter menu (issue 26). The bug: a same-named `.none` tag seen first
/// shadowed the real colored one, so the menu swatch fell back to grey while the
/// row dot stayed colored. Pure, so it runs without a filesystem.
final class FinderTagDistinctTests: XCTestCase {

    /// AC1: a colored instance must win even when a same-named `.none` is seen
    /// first — otherwise the menu shows grey for a tag whose rows show color.
    func testColoredInstanceWinsOverEarlierNoneOfSameName() {
        let lists = [
            [FinderTag(name: "Green", color: .none)],   // seen first (the old bug)
            [FinderTag(name: "Green", color: .green)],
        ]
        XCTAssertEqual(FinderTag.distinctByName(in: lists),
                       [FinderTag(name: "Green", color: .green)])
    }

    /// Order of files must not matter: colored still wins when seen first.
    func testColoredInstanceWinsRegardlessOfOrder() {
        let lists = [
            [FinderTag(name: "Green", color: .green)],
            [FinderTag(name: "Green", color: .none)],
        ]
        XCTAssertEqual(FinderTag.distinctByName(in: lists),
                       [FinderTag(name: "Green", color: .green)])
    }

    /// AC3: a name that is only ever `.none` stays `.none` (its grey dot is right).
    func testGenuinelyColorlessTagStaysNone() {
        let lists = [[FinderTag(name: "Important", color: .none)]]
        XCTAssertEqual(FinderTag.distinctByName(in: lists),
                       [FinderTag(name: "Important", color: .none)])
    }

    /// First-seen order across files is preserved (menu listing stays stable).
    func testPreservesFirstSeenOrder() {
        let lists = [
            [FinderTag(name: "Blue", color: .blue), FinderTag(name: "Red", color: .red)],
            [FinderTag(name: "Green", color: .green), FinderTag(name: "Red", color: .red)],
        ]
        XCTAssertEqual(FinderTag.distinctByName(in: lists).map(\.name),
                       ["Blue", "Red", "Green"])
    }

    /// AC2: all built-in colors survive dedup unchanged.
    func testBuiltInColorsRoundTrip() {
        let lists = FinderTag.standard.map { [$0] }
        XCTAssertEqual(FinderTag.distinctByName(in: lists), FinderTag.standard)
    }

    func testEmptyInputYieldsNoTags() {
        XCTAssertEqual(FinderTag.distinctByName(in: []), [])
        XCTAssertEqual(FinderTag.distinctByName(in: [[], []]), [])
    }
}
