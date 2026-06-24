import XCTest
@testable import Diptychon

/// Slice 1 (issue 15): path-string resolution for Go to Folder. Pure logic vs.
/// the real filesystem (temp dir + known paths).
final class PathInputTests: XCTestCase {
    func testResolvesExistingDirectory() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("dipt-path-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let resolved = PathInput.resolve(dir.path)
        XCTAssertEqual(resolved?.standardizedFileURL, dir.standardizedFileURL)
    }

    func testExpandsTilde() {
        let resolved = PathInput.resolve("~")
        XCTAssertEqual(resolved?.path, FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path)
    }

    func testTrailingSlashAndWhitespaceTolerated() {
        let resolved = PathInput.resolve("  /tmp/  ")
        XCTAssertEqual(resolved?.path, URL(fileURLWithPath: "/tmp").standardizedFileURL.path)
    }

    func testRejectsNonexistentPath() {
        XCTAssertNil(PathInput.resolve("/no/such/path-\(UUID().uuidString)"))
    }

    func testRejectsFileThatIsNotADirectory() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("dipt-file-\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: file.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: file) }

        XCTAssertNil(PathInput.resolve(file.path), "A regular file is not a navigable directory")
    }

    func testRejectsEmpty() {
        XCTAssertNil(PathInput.resolve("   "))
    }
}
