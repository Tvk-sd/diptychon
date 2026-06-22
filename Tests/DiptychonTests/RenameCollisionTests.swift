import XCTest
@testable import Diptychon

/// Unit tests for `renameCollisionIndices` — the pure guard that blocks a batch
/// rename before anything is written. Focus: the case-insensitive-volume rules,
/// including the bug where a case-only rename was wrongly flagged as a collision.
final class RenameCollisionTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("dipt-collide-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func makeFiles(_ names: String...) {
        for name in names {
            FileManager.default.createFile(atPath: dir.appendingPathComponent(name).path, contents: Data())
        }
    }

    // MARK: - The reported bug

    /// Renaming a file to a different case of its OWN name is not a collision —
    /// on either volume kind. (On case-insensitive disk it's the file renaming
    /// itself; on case-sensitive disk the target name doesn't exist yet.)
    func testCaseOnlySelfRenameIsNotACollision() {
        makeFiles("alpha.txt")
        let result = renameCollisionIndices(originals: ["alpha.txt"], newNames: ["ALPHA.txt"], directory: dir)
        XCTAssertTrue(result.isEmpty, "A case-only self-rename must not be blocked")
    }

    // MARK: - Real collisions still caught

    /// Renaming onto an existing file that isn't part of the batch is a collision.
    func testClobberingExistingFileIsACollision() {
        makeFiles("a.txt", "notes.txt")
        let result = renameCollisionIndices(originals: ["a.txt"], newNames: ["notes.txt"], directory: dir)
        XCTAssertEqual(result, [0])
    }

    /// Two outputs mapping to the same name collide (FS-independent).
    func testTwoOutputsSameNameCollide() {
        let result = renameCollisionIndices(originals: ["x.txt", "y.txt"],
                                            newNames: ["same.txt", "same.txt"],
                                            directory: dir, caseInsensitive: true)
        XCTAssertEqual(result, [0, 1])
    }

    /// On a case-insensitive volume, two outputs differing only in case collide;
    /// on a case-sensitive volume they don't.
    func testCaseDifferingOutputsDependOnVolume() {
        let ci = renameCollisionIndices(originals: ["x.txt", "y.txt"],
                                        newNames: ["Foo.txt", "foo.txt"],
                                        directory: dir, caseInsensitive: true)
        XCTAssertEqual(ci, [0, 1], "Case-insensitive volume: Foo.txt and foo.txt are the same name")

        let cs = renameCollisionIndices(originals: ["x.txt", "y.txt"],
                                        newNames: ["Foo.txt", "foo.txt"],
                                        directory: dir, caseInsensitive: false)
        XCTAssertTrue(cs.isEmpty, "Case-sensitive volume: Foo.txt and foo.txt are distinct")
    }

    /// A straight swap (A→B, B→A) is allowed: each name is vacated by its partner.
    func testSwapIsNotACollision() {
        makeFiles("a.txt", "b.txt")
        let result = renameCollisionIndices(originals: ["a.txt", "b.txt"],
                                            newNames: ["b.txt", "a.txt"], directory: dir)
        XCTAssertTrue(result.isEmpty, "A swap is resolvable (two-phase) and must not be blocked")
    }
}
