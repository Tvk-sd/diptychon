import XCTest
@testable import Diptychon

/// Issue 94: picking a folder in *any* column of the browser — the last one included
/// — opens it to the right, while the keyboard stays in the column you picked from.
/// These pin that rule on the model with an injected source (no filesystem), the
/// same seam `PanelFocusSelectionTests` uses.
@MainActor
final class ColumnFocusTests: XCTestCase {

    private struct FakeSource: PanelSource {
        var title: String = "fake"
        var items: [FileItem] = []
        func load() async throws -> [FileItem] { items }
    }

    private let root = URL(fileURLWithPath: "/fake/root", isDirectory: true)
    private var folderA: URL { root.appendingPathComponent("A", isDirectory: true) }
    private var folderB: URL { root.appendingPathComponent("B", isDirectory: true) }
    private var fileX: URL { root.appendingPathComponent("x.txt") }
    private var folderA2: URL { folderA.appendingPathComponent("A2", isDirectory: true) }
    private var fileA1: URL { folderA.appendingPathComponent("z1.txt") }

    private func item(_ url: URL, folder: Bool) -> FileItem {
        FileItem(url: url, name: url.lastPathComponent, size: folder ? nil : 1,
                 modificationDate: nil, isDirectory: folder, tags: [])
    }

    /// A small tree: root holds folders A and B and file x; A holds folder A2 and
    /// file z1 (named so A2 sorts first); everything else is empty.
    private func tree() -> [URL: [FileItem]] {
        [
            root: [item(folderA, folder: true), item(folderB, folder: true), item(fileX, folder: false)],
            folderA: [item(folderA2, folder: true), item(fileA1, folder: false)],
        ]
    }

    private func makePanel() -> PanelModel {
        let tree = tree()
        let panel = PanelModel(directory: root, makeSource: { url, _ in
            FakeSource(items: tree[URL(fileURLWithPath: url.path, isDirectory: true)] ?? [])
        })
        panel.sortOrder = [KeyPathComparator(\FileItem.name)]   // by name, deterministically
        return panel
    }

    /// `openColumn` reloads without a loading state (the rows stay on screen), so
    /// `state` cannot tell us when the new folder's listing has landed — wait for a
    /// row that only that folder has.
    private func settle(_ panel: PanelModel, untilRowNamed name: String) async {
        let deadline = Date().addingTimeInterval(2)
        while !panel.visibleItems.contains(where: { $0.name == name }) {
            if Date() > deadline { break }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    private func settle(_ panel: PanelModel) async {
        let deadline = Date().addingTimeInterval(2)
        while case .loading = panel.state {
            if Date() > deadline { break }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    private func loaded() async -> PanelModel {
        let panel = makePanel()
        panel.load()
        await settle(panel)
        return panel
    }

    // MARK: Picking

    /// The bug itself: a folder picked in the (only) last column opens as the next
    /// column, and the keyboard stays where the pick happened.
    func testPickingFolderInLastColumnOpensItAndKeepsFocus() async {
        let panel = await loaded()
        panel.pickInColumn([folderA], at: root)

        XCTAssertEqual(panel.directory.path, folderA.path)
        XCTAssertEqual(panel.columnChain.map(\.path), [root.path, folderA.path])
        XCTAssertEqual(panel.focusedColumn.path, root.path)
        XCTAssertTrue(panel.selection.isEmpty, "the new last column starts unselected")
    }

    /// The column you picked from keeps its rows the moment it changes hands, so the
    /// list you are typing in never blanks out.
    func testLeftColumnKeepsItsRowsWithoutWaitingForAReload() async {
        let panel = await loaded()
        panel.pickInColumn([folderA], at: root)

        let left = panel.columnModel(for: root)
        XCTAssertFalse(left === panel)
        XCTAssertEqual(left.visibleItems.map(\.name), ["A", "B", "x.txt"])
    }

    /// Stepping ↓ from a folder to a file in the left column cuts the chain back and
    /// selects the file — and the rows are there at once.
    func testPickingFileInLeftColumnCutsChainAndSelectsIt() async {
        let panel = await loaded()
        panel.pickInColumn([folderA], at: root)
        panel.pickInColumn([fileX], at: root)

        XCTAssertEqual(panel.directory.path, root.path)
        XCTAssertEqual(panel.columnChain.map(\.path), [root.path])
        XCTAssertEqual(panel.selection, [fileX])
        XCTAssertEqual(panel.selectedItems.map(\.name), ["x.txt"])
        XCTAssertEqual(panel.focusedColumn.path, root.path)
    }

    /// ↓ from folder A to folder B swaps the right-hand column rather than stacking.
    func testPickingSiblingFolderReplacesTheRightColumn() async {
        let panel = await loaded()
        panel.pickInColumn([folderA], at: root)
        panel.pickInColumn([folderB], at: root)

        XCTAssertEqual(panel.columnChain.map(\.path), [root.path, folderB.path])
        XCTAssertEqual(panel.focusedColumn.path, root.path)
    }

    /// Several rows open nothing (Finder rule); the chain ends at the column and the
    /// pane's selection is the whole set.
    func testMultiSelectionDoesNotOpenAColumn() async {
        let panel = await loaded()
        panel.pickInColumn([folderA, folderB], at: root)

        XCTAssertEqual(panel.columnChain.map(\.path), [root.path])
        XCTAssertEqual(panel.selection, [folderA, folderB])
    }

    // MARK: Stepping

    /// → moves the keyboard into the opened column and picks its first row; a folder
    /// there opens onward at once (story 4 of #91).
    func testStepRightEntersNextColumnAndPicksFirstRow() async {
        let panel = await loaded()
        panel.pickInColumn([folderA], at: root)
        await settle(panel, untilRowNamed: "A2")   // A's listing has to be in before its first row is picked

        panel.stepColumnFocus(right: true)

        XCTAssertEqual(panel.focusedColumn.path, folderA.path)
        XCTAssertEqual(panel.columnChain.map(\.path), [root.path, folderA.path, folderA2.path],
                       "A's first row is folder A2, so it opens to the right")
    }

    /// ← steps the keyboard back without cutting the chain (story 5 of #91).
    func testStepLeftKeepsChainAndHighlight() async {
        let panel = await loaded()
        panel.pickInColumn([folderA], at: root)
        await settle(panel, untilRowNamed: "A2")
        panel.stepColumnFocus(right: true)

        panel.stepColumnFocus(right: false)

        XCTAssertEqual(panel.focusedColumn.path, root.path)
        XCTAssertEqual(panel.columnChain.map(\.path), [root.path, folderA.path, folderA2.path])
    }

    /// → in the last column with a lone folder highlighted (carried over from the
    /// table, say) opens it; the keyboard follows once the rows are there.
    func testStepRightOnHighlightedFolderInLastColumnOpensIt() async {
        let panel = await loaded()
        panel.selection = [folderA]

        panel.stepColumnFocus(right: true)
        XCTAssertEqual(panel.columnChain.map(\.path), [root.path, folderA.path])
        XCTAssertEqual(panel.focusedColumn.path, root.path, "the new column is still listing")

        await settle(panel, untilRowNamed: "A2")
        panel.stepColumnFocus(right: true)
        XCTAssertEqual(panel.focusedColumn.path, folderA.path)
    }

    /// A move reports "deselect, then select": the empty step must not cut the chain.
    func testEmptyPickInAncestorColumnChangesNothing() async {
        let panel = await loaded()
        panel.pickInColumn([folderA], at: root)
        panel.pickInColumn([], at: root)

        XCTAssertEqual(panel.columnChain.map(\.path), [root.path, folderA.path])
        XCTAssertEqual(panel.focusedColumn.path, root.path)
    }

    /// In the last column an empty pick is a real deselect.
    func testEmptyPickInLastColumnClearsSelection() async {
        let panel = await loaded()
        panel.pickInColumn([fileX], at: root)
        panel.pickInColumn([], at: root)
        XCTAssertTrue(panel.selection.isEmpty)
    }

    /// Opening a folder shows a spinner, not the previous folder's rows, until its
    /// listing lands — and → does nothing while it is empty.
    func testOpenedColumnStartsEmptyAndStepRightWaits() async {
        let panel = await loaded()
        panel.pickInColumn([folderA], at: root)

        XCTAssertTrue(panel.visibleItems.isEmpty, "no stale rows under the new header")
        panel.stepColumnFocus(right: true)
        XCTAssertEqual(panel.focusedColumn.path, root.path, "→ waits for rows")
        XCTAssertEqual(panel.columnChain.map(\.path), [root.path, folderA.path])
    }

    /// ← in the first column is a wall; the chain never changes on ←.
    func testStepLeftInFirstColumnDoesNothing() async {
        let panel = await loaded()
        panel.pickInColumn([folderA], at: root)
        panel.stepColumnFocus(right: false)
        XCTAssertEqual(panel.columnChain.map(\.path), [root.path, folderA.path])
        XCTAssertEqual(panel.focusedColumn.path, root.path)
    }

    /// ⌘2 with a folder highlighted in the table: its column is there at once.
    func testEnteringColumnsOpensTheHighlightedFolder() async {
        let panel = await loaded()
        panel.selection = [folderA]
        panel.toggleColumnView()

        XCTAssertEqual(panel.columnChain.map(\.path), [root.path, folderA.path])
        XCTAssertEqual(panel.focusedColumn.path, root.path)
    }

    // MARK: Tab

    /// Tab into a column pane with nothing selected: the home row is picked like a
    /// click, so a folder opens to the right and the keyboard stays in place.
    func testKeyboardHomeInColumnsOpensTheFirstFolder() async {
        let panel = await loaded()
        panel.setDisplayMode(.columns)
        panel.selectFirstRowIfEmpty()

        XCTAssertEqual(panel.columnChain.map(\.path), [root.path, folderA.path])
        XCTAssertEqual(panel.focusedColumn.path, root.path)
    }

    /// Tab into a column pane whose keyboard sits in an ancestor: that column already
    /// has its highlight, so the last column gets none.
    func testKeyboardHomeLeavesAncestorFocusAlone() async {
        let panel = await loaded()
        panel.setDisplayMode(.columns)
        panel.pickInColumn([folderA], at: root)
        await settle(panel, untilRowNamed: "A2")

        panel.selectFirstRowIfEmpty()

        XCTAssertTrue(panel.selection.isEmpty)
        XCTAssertEqual(panel.columnChain.map(\.path), [root.path, folderA.path])
    }

    // MARK: Leaving the tree

    /// A navigation that leaves the chain — sidebar, breadcrumb, ⌘← — drops the
    /// stored focus; it falls to the last column with no reset needed.
    func testNavigatingAwayResetsFocusToLastColumn() async {
        let panel = await loaded()
        panel.pickInColumn([folderA], at: root)
        XCTAssertEqual(panel.focusedColumn.path, root.path)

        let elsewhere = URL(fileURLWithPath: "/fake/elsewhere", isDirectory: true)
        panel.go(to: elsewhere)

        XCTAssertEqual(panel.columnChain.map(\.path), [elsewhere.path])
        XCTAssertEqual(panel.focusedColumn.path, elsewhere.path)
    }

    /// A pane that never navigated since launch still gets a two-column chain on its
    /// first pick, anchored where it opened.
    func testFreshPaneAnchorsAtItsStartFolder() async {
        let panel = await loaded()   // no `go(to:)` before this — the restore path
        panel.pickInColumn([folderA], at: root)
        XCTAssertEqual(panel.columnChain.map(\.path), [root.path, folderA.path])
    }
}
