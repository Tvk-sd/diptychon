import XCTest
@testable import Diptychon

/// The normalized-subsequence matcher shared by recursive Search and the
/// current-folder Filter. Pins the behaviours strict substring couldn't do:
/// trailing punctuation, acronyms, partial words — plus the negatives that keep
/// it from matching everything.
final class FuzzyMatchTests: XCTestCase {
    func testTrailingPunctuationStillMatches() {
        // The reported bug: `digital-` finds `digitalservice`.
        XCTAssertTrue(FuzzyMatch.matches("digital-", in: "digitalservice"))
        XCTAssertTrue(FuzzyMatch.matches("digital", in: "digitalservice"))
    }

    func testSeparatorsIgnoredBothSides() {
        XCTAssertTrue(FuzzyMatch.matches("foobar", in: "foo-bar.txt"))
        XCTAssertTrue(FuzzyMatch.matches("my file", in: "my_file"))
    }

    func testAcronymSubsequence() {
        // Ordered but not contiguous.
        XCTAssertTrue(FuzzyMatch.matches("digserv", in: "digitalservice"))
        XCTAssertTrue(FuzzyMatch.matches("inv23", in: "invoice-2023.pdf"))
    }

    func testCaseInsensitive() {
        XCTAssertTrue(FuzzyMatch.matches("DIGITAL", in: "digitalservice"))
        XCTAssertTrue(FuzzyMatch.matches("bewerbung", in: "Bewerbungen"))
    }

    func testNonSubsequenceRejected() {
        // Right chars, wrong order.
        XCTAssertFalse(FuzzyMatch.matches("latigid", in: "digitalservice"))
        // Missing char.
        XCTAssertFalse(FuzzyMatch.matches("digitalx", in: "digitalservice"))
    }

    func testScoreRanksObviousMatchesAboveScattered() {
        let needle = FuzzyMatch.normalize("digital")
        let prefix = FuzzyMatch.score(needle: needle, candidate: "cv-digitalservice.html")
        let scattered = FuzzyMatch.score(needle: needle, candidate: "Corpid Light Italic")
        XCTAssertNotNil(prefix)
        // The scattered font name may or may not match; if it does, it must rank
        // strictly below the clean prefix hit.
        if let scattered { XCTAssertGreaterThan(prefix!, scattered) }
    }

    func testWordBoundaryBeatsMidWord() {
        // Identical except the separator before "service" — isolates the
        // word-boundary bonus (same match position and length otherwise).
        let needle = FuzzyMatch.normalize("service")
        let boundary = FuzzyMatch.score(needle: needle, candidate: "abc-service")
        let midword = FuzzyMatch.score(needle: needle, candidate: "abcxservice")
        XCTAssertNotNil(boundary)
        XCTAssertNotNil(midword)
        XCTAssertGreaterThan(boundary!, midword!)
    }

    func testEmptyOrPunctuationOnlyQueryMatchesNothing() {
        XCTAssertFalse(FuzzyMatch.matches("", in: "anything"))
        XCTAssertFalse(FuzzyMatch.matches("-", in: "anything"))
        XCTAssertFalse(FuzzyMatch.matches("   ", in: "anything"))
    }
}
