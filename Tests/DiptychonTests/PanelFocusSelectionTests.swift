import XCTest
@testable import Diptychon

/// A fake `PanelSource` — canned rows, no filesystem. Same adapter as
/// `PanelSourceInjectionTests` uses (the ADR-0003 seam).
private struct FakeSource: PanelSource {
    var title: String = "fake"
    var items: [FileItem] = []
    func load() async throws -> [FileItem] { items }
}

/// Issue 86: with the accent border gone, the *selection* shows which panel the
/// keyboard is in. These pin the rule that fills a panel that has none — and, just as
/// importantly, the cases where it must stay out of the way.
@MainActor
final class PanelFocusSelectionTests: XCTestCase {

    private func file(_ name: String) -> FileItem {
        FileItem(url: URL(fileURLWithPath: "/fake/\(name)"), name: name, size: 1,
                 modificationDate: nil, isDirectory: false, tags: [])
    }

    private func makePanel(_ names: [String]) -> PanelModel {
        let fake = FakeSource(items: names.map(file))
        return PanelModel(directory: URL(fileURLWithPath: NSTemporaryDirectory()),
                          makeSource: { _, _ in fake })
    }

    private func loaded(_ names: [String]) async -> PanelModel {
        let panel = makePanel(names)
        panel.load()
        let deadline = Date().addingTimeInterval(2)
        while case .loading = panel.state {
            if Date() > deadline { break }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        return panel
    }

    /// Tab into an untouched panel: it gets a keyboard home.
    func testEmptySelectionTakesTheFirstRow() async {
        let panel = await loaded(["a.txt", "b.txt", "c.txt"])
        XCTAssertTrue(panel.selection.isEmpty)
        panel.selectFirstRowIfEmpty()
        XCTAssertEqual(panel.selectedItems.map(\.name), [panel.visibleItems[0].name])
    }

    /// Switching away and back must never move what the user picked. This is the one
    /// that would bite daily if it broke.
    func testAnExistingSelectionIsLeftAlone() async {
        let panel = await loaded(["a.txt", "b.txt", "c.txt"])
        let second = panel.visibleItems[1]
        panel.selection = [second.id]
        panel.selectFirstRowIfEmpty()
        XCTAssertEqual(panel.selectedItems.map(\.name), [second.name])
    }

    /// A multi-row selection is a selection too — no silent collapse to one row.
    func testAMultiRowSelectionIsLeftAlone() async {
        let panel = await loaded(["a.txt", "b.txt", "c.txt"])
        panel.selection = Set(panel.visibleItems.map(\.id))
        panel.selectFirstRowIfEmpty()
        XCTAssertEqual(panel.selection.count, 3)
    }

    /// An empty folder has no first row. Must not crash and must not invent one.
    func testAnEmptyFolderStaysUnselected() async {
        let panel = await loaded([])
        panel.selectFirstRowIfEmpty()
        XCTAssertTrue(panel.selection.isEmpty)
    }

    /// It follows what the user can *see*: with a filter applied, the home is the
    /// first visible row, not the first row of the unfiltered folder.
    func testItFollowsTheVisibleRowsNotTheWholeFolder() async {
        let panel = await loaded(["apple.txt", "banana.txt", "cherry.txt"])
        panel.filter = "ban"
        panel.selectFirstRowIfEmpty()
        XCTAssertEqual(panel.selectedItems.map(\.name), ["banana.txt"])
    }
}
