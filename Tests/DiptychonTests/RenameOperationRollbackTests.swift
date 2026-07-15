import XCTest
@testable import Diptychon

/// Issue 52: a batch rename must apply fully or not at all. If a move fails
/// mid-batch (e.g. a target name is occupied by a file the collision guard
/// didn't see), every move already made is unwound — no file may ever be left
/// under a hidden `.diptychon-rename-*` temp name.
final class RenameOperationRollbackTests: XCTestCase {
    private var dir: URL!
    private let fm = FileManager.default

    override func setUpWithError() throws {
        dir = fm.temporaryDirectory.appendingPathComponent("dipt-rollback-\(UUID().uuidString)")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? fm.removeItem(at: dir)
    }

    private func url(_ name: String) -> URL { dir.appendingPathComponent(name) }

    private func names() -> Set<String> {
        Set((try? fm.contentsOfDirectory(atPath: dir.path)) ?? [])
    }

    func testMidBatchFailureUnwindsAllMoves() async {
        for name in ["one.txt", "two.txt", "blocker.txt"] {
            fm.createFile(atPath: url(name).path, contents: Data())
        }
        // Second pair's target is occupied → phase 2 fails after the first pair
        // already reached its final name.
        let op = RenameOperation(renames: [
            (from: url("one.txt"), to: url("renamed-one.txt")),
            (from: url("two.txt"), to: url("blocker.txt")),
        ])

        do {
            try await op.apply(progress: { _ in })
            XCTFail("apply should throw when a target name is occupied")
        } catch {
            // expected
        }

        XCTAssertEqual(names(), ["one.txt", "two.txt", "blocker.txt"],
                       "a failed batch must leave the directory exactly as it was")
    }
}
