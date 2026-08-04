import XCTest
@testable import Diptychon

/// Issue 42: `docs/keyboard-reference.md` says it is "generated from the same
/// `Keymap.default` the app dispatches against, so it stays honest" — but no
/// generator ever existed, and by 2026-08-04 the file documented `⌘[` / `⌘]` for
/// history while issue 60 had moved it to ⌘←/⌘→ months earlier. On a German layout
/// `[` is ⌥5, so the documented key was not even typeable on the author's machine.
///
/// This test is the missing generator's replacement: it can't write the file, but it
/// makes drift fail loudly and prints the correct table so fixing it is a paste.
final class DocsKeyboardReferenceTests: XCTestCase {
    /// The docs live in the repo, not in the test bundle — walk up from this file.
    private var referenceURL: URL {
        URL(fileURLWithPath: #filePath)          // Tests/DiptychonTests/<this file>
            .deletingLastPathComponent()          // Tests/DiptychonTests
            .deletingLastPathComponent()          // Tests
            .deletingLastPathComponent()          // repo root
            .appendingPathComponent("docs/keyboard-reference.md")
    }

    /// Chords that appear inside markdown table rows, as code spans.
    private func documentedChords(in markdown: String) -> Set<String> {
        var found: Set<String> = []
        for line in markdown.split(separator: "\n") where line.hasPrefix("|") {
            // `⇧⌘R` → ⇧⌘R. Several chords per row are possible ("`⌘←` / `⌘[`").
            var rest = Substring(line)
            while let open = rest.firstIndex(of: "`") {
                let afterOpen = rest.index(after: open)
                guard let close = rest[afterOpen...].firstIndex(of: "`") else { break }
                let chord = String(rest[afterOpen..<close]).trimmingCharacters(in: .whitespaces)
                if !chord.isEmpty { found.insert(chord) }
                rest = rest[rest.index(after: close)...]
            }
        }
        return found
    }

    func testEveryBoundChordIsDocumented() throws {
        let markdown = try String(contentsOf: referenceURL, encoding: .utf8)
        let documented = documentedChords(in: markdown)

        let missing = Keymap.default
            .map { (glyphs: $0.chord.glyphs, action: $0.action) }
            .filter { !documented.contains($0.glyphs) }

        XCTAssertTrue(
            missing.isEmpty,
            """
            docs/keyboard-reference.md is missing \(missing.count) bound shortcut(s):
            \(missing.map { "  \($0.glyphs)\t\($0.action.displayName)" }.joined(separator: "\n"))

            Full current keymap — paste over the tables in the doc:
            \(Self.markdownTable())
            """
        )
    }

    /// The other direction: a chord printed in the doc that nothing dispatches. This is
    /// what silently rots — issue 60 replaced a binding and the old one lived on in
    /// prose for three weeks.
    func testNoDocumentedChordIsUnbound() throws {
        let markdown = try String(contentsOf: referenceURL, encoding: .utf8)
        let bound = Set(Keymap.default.map(\.chord.glyphs))
        // Single glyphs are the notation legend (⌘, ⌥, ⇧ …), not claims about bindings.
        let claimed = documentedChords(in: markdown).filter { $0.count > 1 }

        let unbound = claimed.subtracting(bound).sorted()
        XCTAssertTrue(
            unbound.isEmpty,
            "docs/keyboard-reference.md documents shortcuts nothing dispatches: \(unbound)"
        )
    }

    /// Printed by the failure above so regenerating the doc is copy-paste.
    static func markdownTable() -> String {
        let rows = Keymap.default.map { "| `\($0.chord.glyphs)` | \($0.action.displayName) |" }
        return (["| Shortcut | Action |", "|----------|--------|"] + rows).joined(separator: "\n")
    }
}
