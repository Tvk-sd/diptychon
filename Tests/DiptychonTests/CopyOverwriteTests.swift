import XCTest
@testable import Diptychon

/// `CopyOperation` overwrite safety. The dangerous case: pasting a file into the
/// folder it already lives in and choosing Overwrite — `dest == src`, so a naive
/// remove-then-copy destroys the file (and overwrite is not undoable, ADR-0004).
final class CopyOverwriteTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("dipt-copy-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { [dir] in try? FileManager.default.removeItem(at: dir!) }
    }

    private func makeFile(_ name: String, contents: String) throws -> URL {
        let url = dir.appendingPathComponent(name)
        try Data(contents.utf8).write(to: url)
        return url
    }

    func testSelfOverwriteLeavesFileIntact() async throws {
        let file = try makeFile("note.txt", contents: "keep me")

        // Paste "note.txt" into its own directory, resolve as Overwrite.
        let op = CopyOperation(sources: [file], destinationDirectory: dir, resolution: .overwrite)
        try await op.apply { _ in }

        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path), "self-overwrite must not delete the file")
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "keep me", "contents unchanged")
        XCTAssertTrue(op.isUndoable, "a self-overwrite no-op did not destroy anything, so it stays undoable")
    }

    /// The real paste path round-trips the source URL through `NSPasteboard`, which
    /// returns the symlink-resolved form (`/private/var/…`) while the Panel directory
    /// stays `/var/…`. The self-overwrite guard must still recognise them as the same
    /// file. Reproduced deterministically by resolving symlinks on the source only.
    func testSelfOverwriteSurvivesSymlinkResolvedSource() async throws {
        let file = try makeFile("note.txt", contents: "keep me")
        let resolvedSource = file.resolvingSymlinksInPath() // mimics the pasteboard round-trip

        let op = CopyOperation(sources: [resolvedSource], destinationDirectory: dir, resolution: .overwrite)
        try await op.apply { _ in }

        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path),
                      "self-overwrite must survive a symlink-resolved source path")
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "keep me")
    }

    /// The exact real-app path: source URL survives an `NSPasteboard` round-trip
    /// (⌘C → clipboardURLs()) before the self-overwrite paste. This is the case the
    /// user reported; it must not delete the file.
    func testSelfOverwriteThroughPasteboardLeavesFileIntact() async throws {
        let file = try makeFile("note.txt", contents: "keep me")

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([file as NSURL])
        let readBack = (pb.readObjects(forClasses: [NSURL.self]) as? [URL]) ?? []
        XCTAssertEqual(readBack.count, 1, "pasteboard returned the file URL")

        let op = CopyOperation(sources: readBack, destinationDirectory: dir, resolution: .overwrite)
        try await op.apply { _ in }

        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path),
                      "self-overwrite via the real pasteboard path must keep the file. readBack=\(readBack.first?.path ?? "nil") dir=\(dir.path)")
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "keep me")
    }

    func testCopyIntoSubfolderStillOverwrites() async throws {
        // A real overwrite (different location, same name) must still replace.
        let sub = dir.appendingPathComponent("sub")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let src = try makeFile("note.txt", contents: "new")
        let existing = sub.appendingPathComponent("note.txt")
        try Data("old".utf8).write(to: existing)

        let op = CopyOperation(sources: [src], destinationDirectory: sub, resolution: .overwrite)
        try await op.apply { _ in }

        XCTAssertEqual(try String(contentsOf: existing, encoding: .utf8), "new", "genuine overwrite still replaces")
    }
}
