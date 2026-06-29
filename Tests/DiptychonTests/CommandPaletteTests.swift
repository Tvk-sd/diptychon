import XCTest
@testable import Diptychon

/// Issue 19: the palette's pure pieces — fuzzy filtering and the Keymap-driven
/// chord glyphs (so palette labels can't drift from the actual keymap).
final class CommandPaletteTests: XCTestCase {

    // MARK: Fuzzy match
    func testEmptyQueryMatchesEverythingInOrder() {
        XCTAssertEqual(CommandCatalog.fuzzyScore("", "Anything"), 0)
        XCTAssertEqual(CommandCatalog.filter("").count, CommandCatalog.commands.count)
    }

    func testSubsequenceMatchesAndNonMatchIsNil() {
        XCTAssertNotNil(CommandCatalog.fuzzyScore("nf", "New Folder"))   // N…F
        XCTAssertNil(CommandCatalog.fuzzyScore("zzz", "New Folder"))
    }

    func testEarlierContiguousMatchScoresBetter() {
        // Contiguous-at-start beats a gap, which beats a later start.
        XCTAssertEqual(CommandCatalog.fuzzyScore("ab", "ab"), 0)
        XCTAssertLessThan(CommandCatalog.fuzzyScore("ab", "ab")!,   // contiguous, start
                          CommandCatalog.fuzzyScore("ab", "axb")!)  // one gap
        XCTAssertLessThan(CommandCatalog.fuzzyScore("ab", "xab")!,  // later start, no gap
                          CommandCatalog.fuzzyScore("ab", "xaxb")!) // later start + gap
        XCTAssertNil(CommandCatalog.fuzzyScore("ba", "ab"))         // wrong order ⇒ no match
    }

    func testFilterSurfacesExpectedCommandFirst() {
        let top = CommandCatalog.filter("trash").first
        XCTAssertEqual(top?.title, "Move to Trash")
    }

    // MARK: Glyphs from Keymap (data-driven, no drift)
    func testGlyphsForLetterChords() {
        XCTAssertEqual(Keymap.glyphs(for: .revealInFinder), "⇧⌘R")
        XCTAssertEqual(Keymap.glyphs(for: .copyPaths), "⌥⌘C")
        XCTAssertEqual(Keymap.glyphs(for: .openPalette), "⌘K")
    }

    func testGlyphsForCodeChords() {
        XCTAssertEqual(Keymap.glyphs(for: .trash), "⌘⌫")        // ⌘ + Backspace
        XCTAssertEqual(Keymap.glyphs(for: .moveToInactive), "⌥⇧⌘→") // canonical ⌃⌥⇧⌘ order
    }

    // MARK: Catalog hygiene
    func testPaletteDoesNotListItself() {
        XCTAssertFalse(CommandCatalog.commands.contains { $0.id == "openPalette" })
    }
}
