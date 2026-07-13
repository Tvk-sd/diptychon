import XCTest
@testable import Diptychon

/// Unit tests for `RenameRule.newName` — the pure name computation behind the
/// batch-rename sheet. Focus: the issue-52 `numberPrefix` mode, which KEEPS the
/// existing name (unlike `format`, which replaces it).
final class RenameRuleTests: XCTestCase {

    /// The reporter's exact expectation: "0 report.pdf", "1 photo.jpg", "2 assets" —
    /// ascending from 0, space separator, existing names (and folders) intact.
    func testNumberPrefixKeepsNamesAndCountsFromZero() {
        let rule = RenameRule.numberPrefix(start: 0, padding: 1)
        XCTAssertEqual(rule.newNames(for: ["report.pdf", "photo.jpg", "assets"]),
                       ["0 report.pdf", "1 photo.jpg", "2 assets"])
    }

    func testNumberPrefixCustomStartAndPadding() {
        let rule = RenameRule.numberPrefix(start: 9, padding: 3)
        XCTAssertEqual(rule.newNames(for: ["a.txt", "b.txt"]),
                       ["009 a.txt", "010 b.txt"])
    }

    /// Extension handling matches the other modes: only the LAST extension is
    /// split off and re-appended, so the prefix lands before the full base name.
    func testNumberPrefixPreservesCompoundExtension() {
        let rule = RenameRule.numberPrefix(start: 0, padding: 1)
        XCTAssertEqual(rule.newName(for: "archive.tar.gz", index: 0), "0 archive.tar.gz")
    }

    /// Contrast guard: `format` REPLACES the name — the reason numberPrefix exists.
    func testFormatReplacesTheNameEntirely() {
        let rule = RenameRule.format(name: "File", start: 1, padding: 2)
        XCTAssertEqual(rule.newName(for: "report.pdf", index: 0), "File 01.pdf")
    }
}
