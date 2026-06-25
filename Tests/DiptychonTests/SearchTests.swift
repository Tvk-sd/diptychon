import XCTest
@testable import Diptychon

/// Covers the recursive search walk (issue 21 slice 3): nested matching, hidden
/// visibility, and the empty-query short-circuit.
final class SearchTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("diptychon-search-\(UUID().uuidString)")
        let fm = FileManager.default
        try fm.createDirectory(at: root.appendingPathComponent("sub/deep"), withIntermediateDirectories: true)
        try fm.createDirectory(at: root.appendingPathComponent("other"), withIntermediateDirectories: true)
        // Tree: top.txt, sub/invoice.txt, sub/deep/invoice_old.txt, other/notes.md, .secret_invoice
        try "".write(to: root.appendingPathComponent("top.txt"), atomically: true, encoding: .utf8)
        try "".write(to: root.appendingPathComponent("sub/invoice.txt"), atomically: true, encoding: .utf8)
        try "".write(to: root.appendingPathComponent("sub/deep/invoice_old.txt"), atomically: true, encoding: .utf8)
        try "".write(to: root.appendingPathComponent("other/notes.md"), atomically: true, encoding: .utf8)
        try "".write(to: root.appendingPathComponent(".secret_invoice"), atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    func testFindsNestedMatchesCaseInsensitive() async throws {
        let results = await RecursiveSearch.run(query: "INVOICE", in: root, includeHidden: false)
        let names = Set(results.map(\.name))
        XCTAssertTrue(names.contains("invoice.txt"))        // sub/
        XCTAssertTrue(names.contains("invoice_old.txt"))    // sub/deep/
        XCTAssertFalse(names.contains("top.txt"))           // no match
        XCTAssertFalse(names.contains("notes.md"))          // no match
    }

    func testHiddenExcludedByDefaultIncludedWhenAsked() async throws {
        let visible = await RecursiveSearch.run(query: "invoice", in: root, includeHidden: false)
        XCTAssertFalse(visible.map(\.name).contains(".secret_invoice"))

        let withHidden = await RecursiveSearch.run(query: "invoice", in: root, includeHidden: true)
        XCTAssertTrue(withHidden.map(\.name).contains(".secret_invoice"))
    }

    func testEmptyQueryReturnsNothing() async throws {
        let results = await RecursiveSearch.run(query: "   ", in: root, includeHidden: false)
        XCTAssertTrue(results.isEmpty)
    }
}
