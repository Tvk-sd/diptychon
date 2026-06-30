import XCTest
@testable import Diptychon

/// Issue 20 slice 1: the staging set loads URLs gathered from different folders into
/// one listing, and degrades gracefully when a staged file has gone missing.
final class StagingSourceTests: XCTestCase {

    private var root: URL!

    override func setUpWithError() throws {
        root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("staging-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    /// Create `name` under a fresh subfolder of `root` and return its URL.
    private func makeFile(_ name: String, inSubfolder folder: String) throws -> URL {
        let dir = root.appendingPathComponent(folder)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(name)
        try Data("x".utf8).write(to: url)
        return url
    }

    func testLoadsFilesGatheredAcrossDifferentFolders() async throws {
        let a = try makeFile("alpha.txt", inSubfolder: "one")
        let b = try makeFile("beta.txt", inSubfolder: "two")

        let source = StagingSource(urls: [a, b])
        let items = try await source.load()

        XCTAssertEqual(items.map(\.name), ["alpha.txt", "beta.txt"],
                       "preserves insertion order, even across folders")
        XCTAssertEqual(items.map(\.url), [a, b])
        XCTAssertFalse(items.contains { $0.isMissing }, "present files are not flagged missing")
    }

    func testDeletedFileComesBackFlaggedMissing() async throws {
        let present = try makeFile("here.txt", inSubfolder: "one")
        let gone = try makeFile("gone.txt", inSubfolder: "two")
        try FileManager.default.removeItem(at: gone)

        let source = StagingSource(urls: [present, gone])
        let items = try await source.load()

        XCTAssertEqual(items.count, 2, "the missing file is kept in the listing, not dropped")
        XCTAssertFalse(items[0].isMissing)
        XCTAssertTrue(items[1].isMissing, "a since-deleted staged file is flagged missing")
        XCTAssertEqual(items[1].name, "gone.txt", "missing rows still show their last-known name")
    }

    func testStoreAddPreservesOrderAndDedupes() async {
        let store = await StagingStore()
        let x = URL(fileURLWithPath: "/tmp/x")
        let y = URL(fileURLWithPath: "/tmp/y")

        await store.add([x, y])
        await store.add([x])   // duplicate — ignored

        let urls = await store.urls
        XCTAssertEqual(urls, [x, y], "ordered set: dedupes, keeps first-seen order")
    }
}
