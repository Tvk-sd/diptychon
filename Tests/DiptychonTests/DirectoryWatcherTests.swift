import XCTest
@testable import Diptychon

/// Slice 4 (AC3): the directory watcher fires when its directory's contents
/// change on disk. Real temp-dir integration test (the watcher is OS-backed).
final class DirectoryWatcherTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("dipt-watch-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func testFiresWhenFileCreated() {
        let exp = expectation(description: "watcher fires on create")
        exp.assertForOverFulfill = false
        let watcher = DirectoryWatcher(url: dir, debounceInterval: 0.05) { exp.fulfill() }
        FileManager.default.createFile(atPath: dir.appendingPathComponent("new.txt").path, contents: nil)
        wait(for: [exp], timeout: 5)
        watcher.stop()
    }

    func testFiresWhenFileRemoved() throws {
        let file = dir.appendingPathComponent("gone.txt")
        FileManager.default.createFile(atPath: file.path, contents: nil)

        let exp = expectation(description: "watcher fires on remove")
        exp.assertForOverFulfill = false
        let watcher = DirectoryWatcher(url: dir, debounceInterval: 0.05) { exp.fulfill() }
        try FileManager.default.removeItem(at: file)
        wait(for: [exp], timeout: 5)
        watcher.stop()
    }
}
