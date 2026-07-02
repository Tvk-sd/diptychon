import XCTest
@testable import Diptychon

/// Repeatable load-path baseline (issue 22). Times `LocalDirectorySource.load()`
/// — the off-main enumeration + row build that dominates a folder's
/// time-to-interactive (the `NSTableView` is virtualized, so first render is
/// O(visible rows), not O(items)). Cold-launch and the in-app render are measured
/// separately via the `Perf` unified-log lines; see `context/performance.md`.
///
/// Fixture size defaults to 50k (issue 01's spot-checked scale). Override with
/// `DIPTYCHON_PERF_FILE_COUNT=<n>` for a faster local run.
final class LoadPerformanceTests: XCTestCase {
    private var dir: URL!
    private var fileCount = 0

    override func setUpWithError() throws {
        fileCount = ProcessInfo.processInfo.environment["DIPTYCHON_PERF_FILE_COUNT"]
            .flatMap(Int.init) ?? 50_000
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("diptychon-perf-\(UUID().uuidString)")
        let fm = FileManager.default
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        // Mix in some directories so the row build exercises the isDirectory branch,
        // matching a real folder rather than a flat file dump.
        for i in 0..<fileCount {
            let child = dir.appendingPathComponent("item-\(i)")
            if i % 20 == 0 {
                try fm.createDirectory(at: child, withIntermediateDirectories: false)
            } else {
                fm.createFile(atPath: child.path, contents: nil)
            }
        }
    }

    override func tearDownWithError() throws {
        if let dir { try? FileManager.default.removeItem(at: dir) }
    }

    func testLoadLargeFolderBaseline() async throws {
        let source = LocalDirectorySource(directory: dir)

        // Sanity: the fixture is fully enumerated before we trust the timing.
        let items = try await source.load()
        XCTAssertEqual(items.count, fileCount, "fixture fully enumerated")

        // Warm-cache baseline: repeated loads of the same directory (XCTest runs
        // the block ~10× and reports the average). Regressions in the enumeration
        // or per-row build show up here.
        measure {
            let done = expectation(description: "load")
            Task {
                _ = try? await source.load()
                done.fulfill()
            }
            wait(for: [done], timeout: 60)
        }
    }
}
