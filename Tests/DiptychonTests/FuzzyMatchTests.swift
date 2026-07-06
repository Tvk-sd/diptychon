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

    func testEmptyOrPunctuationOnlyQueryMatchesNothing() {
        XCTAssertFalse(FuzzyMatch.matches("", in: "anything"))
        XCTAssertFalse(FuzzyMatch.matches("-", in: "anything"))
        XCTAssertFalse(FuzzyMatch.matches("   ", in: "anything"))
    }
}
