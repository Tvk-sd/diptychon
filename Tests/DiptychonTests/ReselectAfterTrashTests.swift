import XCTest
@testable import Diptychon

/// Issue 53 — after a trash, the selection lands on the nearest surviving row
/// (Finder parity), driven by `armReselectAfterTrash()` + the pending intent
/// consumed when the trashed rows actually leave `visibleItems`. Uses an
/// injected source whose items can change between reloads — the unit-level
/// equivalent of "the files are gone after the async trash".
private struct FakeSource: PanelSource {
    var title: String = "fake"
    let box: ItemsBox
    func load() async throws -> [FileItem] { box.items }
}

/// Mutable item store shared across reloads: mutate `items`, call `refresh()`,
/// and the next load "sees the deletion".
private final class ItemsBox {
    var items: [FileItem] = []
    init(_ items: [FileItem]) { self.items = items }
}

@MainActor
final class ReselectAfterTrashTests: XCTestCase {

    private func file(_ name: String) -> FileItem {
        FileItem(url: URL(fileURLWithPath: "/fake/\(name)"), name: name, size: 1,
                 modificationDate: nil, isDirectory: false, tags: [])
    }

    /// Panel over a mutable fake source, loaded and name-sorted (deterministic
    /// visual order for the index math under test).
    private func makeLoadedPanel(_ box: ItemsBox) async -> PanelModel {
        let panel = PanelModel(directory: URL(fileURLWithPath: NSTemporaryDirectory()),
                               makeSource: { _, _ in FakeSource(box: box) })
        panel.sortOrder = [KeyPathComparator(\FileItem.name)]
        panel.load()
        _ = await waitUntil { if case .loaded = panel.state { return true }; return false }
        return panel
    }

    private func waitUntil(timeout: TimeInterval = 2,
                           _ condition: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > deadline { return false }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        return true
    }

    private func select(_ names: [String], in panel: PanelModel) {
        panel.selection = Set(panel.visibleItems.filter { names.contains($0.name) }.map(\.id))
    }

    /// Deleting a middle row → the row that slid into its index is selected.
    func testSingleDeleteSelectsRowThatTookItsPlace() async {
        let box = ItemsBox([file("a.txt"), file("b.txt"), file("c.txt"), file("d.txt")])
        let panel = await makeLoadedPanel(box)
        select(["b.txt"], in: panel)

        panel.armReselectAfterTrash()
        box.items = [file("a.txt"), file("c.txt"), file("d.txt")]
        panel.refresh()

        let ok = await waitUntil { panel.selectedItems.map(\.name) == ["c.txt"] }
        XCTAssertTrue(ok, "expected c.txt selected, got \(panel.selectedItems.map(\.name))")
    }

    /// Deleting the last row → the new last row is selected (index clamps).
    func testDeleteLastRowSelectsNewLastRow() async {
        let box = ItemsBox([file("a.txt"), file("b.txt"), file("c.txt"), file("d.txt")])
        let panel = await makeLoadedPanel(box)
        select(["d.txt"], in: panel)

        panel.armReselectAfterTrash()
        box.items = [file("a.txt"), file("b.txt"), file("c.txt")]
        panel.refresh()

        let ok = await waitUntil { panel.selectedItems.map(\.name) == ["c.txt"] }
        XCTAssertTrue(ok, "expected c.txt selected, got \(panel.selectedItems.map(\.name))")
    }

    /// Multi-selection delete → selection lands at the smallest deleted index.
    func testMultiDeleteSelectsAtSmallestDeletedIndex() async {
        let box = ItemsBox([file("a.txt"), file("b.txt"), file("c.txt"), file("d.txt")])
        let panel = await makeLoadedPanel(box)
        select(["b.txt", "d.txt"], in: panel)

        panel.armReselectAfterTrash()
        box.items = [file("a.txt"), file("c.txt")]
        panel.refresh()

        let ok = await waitUntil { panel.selectedItems.map(\.name) == ["c.txt"] }
        XCTAssertTrue(ok, "expected c.txt selected, got \(panel.selectedItems.map(\.name))")
    }

    /// Deleting the only item → empty selection, no crash.
    func testDeleteOnlyItemLeavesEmptySelection() async {
        let box = ItemsBox([file("a.txt")])
        let panel = await makeLoadedPanel(box)
        select(["a.txt"], in: panel)

        panel.armReselectAfterTrash()
        box.items = []
        panel.refresh()

        let ok = await waitUntil { panel.visibleItems.isEmpty }
        XCTAssertTrue(ok, "row should be gone")
        XCTAssertTrue(panel.selection.isEmpty, "empty directory → empty selection")
    }

    /// The rule holds inside a Filter: the reselect targets the nearest
    /// surviving VISIBLE row, not the raw directory index.
    func testReselectWithinFilteredRows() async {
        let box = ItemsBox([file("apple.txt"), file("apricot.txt"), file("banana.txt")])
        let panel = await makeLoadedPanel(box)
        panel.filter = "ap"   // visible: apple, apricot
        select(["apricot.txt"], in: panel)

        panel.armReselectAfterTrash()
        box.items = [file("apple.txt"), file("banana.txt")]
        panel.refresh()

        let ok = await waitUntil { panel.selectedItems.map(\.name) == ["apple.txt"] }
        XCTAssertTrue(ok, "expected apple.txt selected, got \(panel.selectedItems.map(\.name))")
    }

    /// A user-driven filter change cancels a stale intent — rows disappearing
    /// because they're filtered out must NOT trigger a reselect (e.g. after a
    /// failed trash).
    func testFilterChangeCancelsStaleIntent() async {
        let box = ItemsBox([file("a.txt"), file("b.txt"), file("c.txt")])
        let panel = await makeLoadedPanel(box)
        select(["b.txt"], in: panel)

        panel.armReselectAfterTrash()
        panel.filter = "c"   // b vanishes from view — filtered, not deleted

        let ok = await waitUntil { panel.visibleItems.map(\.name) == ["c.txt"] }
        XCTAssertTrue(ok)
        XCTAssertEqual(panel.selection, Set([URL(fileURLWithPath: "/fake/b.txt")]),
                       "selection must stay on the (hidden) b.txt — no reselect jump")
    }
}
