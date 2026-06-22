import XCTest
@testable import Diptychon

/// Tests `SetTagsOperation` apply/revert against real files — the undoable
/// set/remove that backs the tag picker (AC2, ADR 0004).
final class SetTagsOperationTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("dipt-tagop-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { [dir] in try? FileManager.default.removeItem(at: dir!) }
    }

    private func makeFile(_ name: String, tags: [FinderTag] = []) throws -> URL {
        let url = dir.appendingPathComponent(name)
        FileManager.default.createFile(atPath: url.path, contents: Data())
        if !tags.isEmpty { try FinderTag.write(tags, to: url) }
        return url
    }

    func testApplyThenRevertRestoresPriorTags() async throws {
        let red = FinderTag(name: "Red", color: .red)
        let blue = FinderTag(name: "Blue", color: .blue)

        let a = try makeFile("a.txt")               // starts untagged
        let b = try makeFile("b.txt", tags: [blue]) // starts with Blue

        let op = SetTagsOperation(targets: [(a, [red]), (b, [red, blue])])
        try await op.apply { _ in }

        XCTAssertEqual(FinderTag.read(from: a), [red])
        XCTAssertEqual(Set(FinderTag.read(from: b)), [red, blue])

        try await op.revert()

        XCTAssertEqual(FinderTag.read(from: a), [], "revert restores untagged")
        XCTAssertEqual(FinderTag.read(from: b), [blue], "revert restores the prior tag set")
    }
}
