import XCTest
@testable import Diptychon

/// Issue 36: `gadgets.json` decoding — tolerant per entry, loud per problem.
final class GadgetConfigTests: XCTestCase {

    private func decode(_ json: String) -> GadgetConfig.LoadResult {
        GadgetConfig.decode(json.data(using: .utf8)!)
    }

    func testValidConfigDecodesBothTypes() {
        let result = decode("""
        { "gadgets": [
            { "id": "app", "name": "Open in X", "type": "application", "target": "/Applications/X.app" },
            { "id": "exe", "name": "Run Y", "type": "executable", "target": "/usr/bin/y",
              "args": ["-v", "${active.selection.paths}"], "workingDirectory": "${active.folder.path}" }
        ]}
        """)
        XCTAssertEqual(result.errors, [])
        XCTAssertEqual(result.gadgets.map(\.id), ["app", "exe"])
        XCTAssertEqual(result.gadgets[1].args, ["-v", "${active.selection.paths}"])
    }

    func testMalformedJSONReportsErrorAndNoGadgets() {
        let result = decode("{ not json")
        XCTAssertTrue(result.gadgets.isEmpty)
        XCTAssertEqual(result.errors.count, 1)
    }

    /// One broken entry must not take down the valid ones.
    func testBadEntryIsSkippedGoodOnesKept() {
        let result = decode("""
        { "gadgets": [
            { "id": "ok", "name": "Fine", "type": "application", "target": "/Applications/X.app" },
            { "id": "broken", "name": "No target", "type": "executable" },
            { "id": "weird", "name": "Bad type", "type": "lua-plugin", "target": "/x" }
        ]}
        """)
        XCTAssertEqual(result.gadgets.map(\.id), ["ok"])
        XCTAssertEqual(result.errors.count, 2)
    }

    func testDuplicateIdIsSkippedWithError() {
        let result = decode("""
        { "gadgets": [
            { "id": "same", "name": "First", "type": "application", "target": "/a.app" },
            { "id": "same", "name": "Second", "type": "application", "target": "/b.app" }
        ]}
        """)
        XCTAssertEqual(result.gadgets.map(\.name), ["First"])
        XCTAssertEqual(result.errors.count, 1)
    }

    func testEmptyRequiredFieldIsAnError() {
        let result = decode("""
        { "gadgets": [ { "id": "x", "name": " ", "type": "application", "target": "/a.app" } ] }
        """)
        XCTAssertTrue(result.gadgets.isEmpty)
        XCTAssertEqual(result.errors.count, 1)
    }

    func testMissingFileMeansNoGadgetsNoErrors() {
        let result = GadgetConfig.load(from: URL(fileURLWithPath: "/nonexistent/\(UUID())/gadgets.json"))
        XCTAssertEqual(result, GadgetConfig.LoadResult())
    }

    /// The starter written by "Gadgets: Edit Config" must itself parse cleanly.
    func testStarterConfigDecodesCleanly() {
        let result = decode(GadgetStore.starterConfig)
        XCTAssertEqual(result.errors, [])
        XCTAssertEqual(result.gadgets.count, 2)
    }
}
