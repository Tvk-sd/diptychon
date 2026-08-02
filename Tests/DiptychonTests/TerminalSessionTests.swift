import XCTest
@testable import Diptychon

/// Issue 65: the quoting that turns a folder path into a `cd` the shell can't
/// misread. A file manager routinely hands the terminal paths with spaces, umlauts
/// and shell metacharacters — this is the one place a bad path becomes executed text.
final class TerminalSessionTests: XCTestCase {

    func testPlainPathIsQuoted() {
        XCTAssertEqual(TerminalSession.shellQuoted("/Users/x/Projects"), "'/Users/x/Projects'")
    }

    func testSpacesAndUmlautsSurviveIntact() {
        XCTAssertEqual(TerminalSession.shellQuoted("/tmp/Test Ördner mit Leerzeichen"),
                       "'/tmp/Test Ördner mit Leerzeichen'")
    }

    /// The dangerous one: a single quote in a filename would otherwise close the
    /// quoting and leave the rest of the path as bare shell input.
    func testSingleQuoteIsEscapedNotClosed() {
        XCTAssertEqual(TerminalSession.shellQuoted("/tmp/Till's Files"),
                       #"'/tmp/Till'\''s Files'"#)
    }

    /// Inside single quotes these are literal, so quoting alone is enough — no
    /// backslash-escaping needed, and adding it would corrupt the path.
    func testShellMetacharactersStayLiteral() {
        XCTAssertEqual(TerminalSession.shellQuoted("/tmp/$HOME `whoami` & ;"),
                       "'/tmp/$HOME `whoami` & ;'")
    }

    func testNewlineInPathIsContainedByTheQuotes() {
        let quoted = TerminalSession.shellQuoted("/tmp/two\nlines")
        XCTAssertEqual(quoted, "'/tmp/two\nlines'")
        // No unbalanced quote — an odd count would mean the shell keeps reading.
        XCTAssertEqual(quoted.filter { $0 == "'" }.count % 2, 0)
    }
}
