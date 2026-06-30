import XCTest
@testable import Diptychon

/// A fake `PanelSource` — returns canned rows or throws. The second adapter that
/// makes the ADR-0003 seam real: it lets these tests drive a whole `PanelModel`
/// (load → state → filter/sort) with no filesystem.
private struct FakeSource: PanelSource {
    var title: String = "fake"
    var items: [FileItem] = []
    var error: Error?

    func load() async throws -> [FileItem] {
        if let error { throw error }
        return items
    }
}

@MainActor
final class PanelSourceInjectionTests: XCTestCase {

    private func file(_ name: String, isDir: Bool = false) -> FileItem {
        FileItem(url: URL(fileURLWithPath: "/fake/\(name)"), name: name, size: 1,
                 modificationDate: nil, isDirectory: isDir, tags: [])
    }

    /// A panel wired to a fake source. Uses a real temp dir so the directory
    /// watcher is happy; the listing itself comes from the fake, not disk.
    private func makePanel(items: [FileItem] = [], error: Error? = nil) -> PanelModel {
        let fake = FakeSource(items: items, error: error)
        return PanelModel(directory: URL(fileURLWithPath: NSTemporaryDirectory()),
                          makeSource: { _, _ in fake })
    }

    private func waitUntilNotLoading(_ panel: PanelModel, timeout: TimeInterval = 2) async {
        let deadline = Date().addingTimeInterval(timeout)
        while case .loading = panel.state {
            if Date() > deadline { return }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    func testLoadTransitionsToLoadedAndPublishesRows() async {
        let panel = makePanel(items: [file("b.txt"), file("a.txt")])
        panel.load()
        await waitUntilNotLoading(panel)

        guard case .loaded = panel.state else { return XCTFail("expected .loaded, got \(panel.state)") }
        panel.sortOrder = [KeyPathComparator(\FileItem.name)]   // explicit: assert load + sort, not the default
        XCTAssertEqual(panel.visibleItems.map(\.name), ["a.txt", "b.txt"], "rows sort by name ascending")
    }

    func testPermissionErrorSetsAccessDenied() async {
        let denied = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError)
        let panel = makePanel(error: denied)
        panel.load()
        await waitUntilNotLoading(panel)

        XCTAssertTrue(panel.accessDenied, "permission error drives the Full Disk Access guidance")
        guard case .failed = panel.state else { return XCTFail("expected .failed, got \(panel.state)") }
    }

    func testNonPermissionErrorFailsWithoutAccessDenied() async {
        let other = NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError)
        let panel = makePanel(error: other)
        panel.load()
        await waitUntilNotLoading(panel)

        XCTAssertFalse(panel.accessDenied, "only a permission error sets accessDenied")
        guard case .failed = panel.state else { return XCTFail("expected .failed, got \(panel.state)") }
    }

    func testFilterNarrowsVisibleRows() async {
        let panel = makePanel(items: [file("apple.txt"), file("banana.txt")])
        panel.load()
        await waitUntilNotLoading(panel)

        panel.filter = "ban"
        XCTAssertEqual(panel.visibleItems.map(\.name), ["banana.txt"])
    }
}
