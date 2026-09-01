import XCTest
@testable import Diptychon

/// Issue 91: the column browser's chain, and the persistence precedence that decides
/// which of the three display modes comes back.
///
/// The chain is a pure function of the pane's directory, which is the whole point of
/// the design — so the behaviour of the view is testable without a window. Same shape
/// as `ColumnChain`'s sibling tests for the breadcrumb trail.
final class ColumnChainTests: XCTestCase {

    private func names(_ urls: [URL]) -> [String] {
        urls.map { $0.lastPathComponent.isEmpty ? "/" : $0.lastPathComponent }
    }

    // MARK: - The chain

    func testChainIsAncestorsThenTheFolderItself() {
        let chain = ColumnChain.columns(for: URL(fileURLWithPath: "/Users/Till/Projects"))
        XCTAssertEqual(names(chain), ["/", "Users", "Till", "Projects"])
    }

    /// The last column is always the pane's own folder — that is what lets the pane's
    /// existing list serve as it, and why nothing else in the app needs to change.
    func testTheLastColumnIsTheFolderItself() {
        let dir = URL(fileURLWithPath: "/Users/Till/Projects")
        XCTAssertEqual(ColumnChain.columns(for: dir).last?.path, dir.path)
    }

    func testRootIsASingleColumn() {
        XCTAssertEqual(names(ColumnChain.columns(for: URL(fileURLWithPath: "/"))), ["/"])
    }

    /// Till's own working directory has a space in it; a chain that split on spaces
    /// would land him in a folder that doesn't exist.
    func testASpaceInTheNameDoesNotSplitAColumn() {
        let chain = ColumnChain.columns(for: URL(fileURLWithPath: "/Users/Till/Projects/untitled folder"))
        XCTAssertEqual(names(chain).last, "untitled folder")
        XCTAssertEqual(chain.count, 5)
    }

    /// Directory-style URLs (trailing slash) are what `contentsOfDirectory` hands back.
    /// They must produce the same chain as the plain form — the looping
    /// `deletingLastPathComponent` approach never converged for these (issue 21).
    func testATrailingSlashChangesNothing() {
        let plain = ColumnChain.columns(for: URL(fileURLWithPath: "/Users/Till"))
        let slashed = ColumnChain.columns(for: URL(fileURLWithPath: "/Users/Till", isDirectory: true))
        XCTAssertEqual(names(plain), names(slashed))
    }

    // MARK: - The anchor (Till, 2026-09-01)

    /// The point of the anchor: navigating to Projects makes **Projects** the first
    /// column, not `/` with Users and Till in front of it. The chain grows to the
    /// right as you walk in.
    func testTheChainStartsAtTheFolderYouNavigatedTo() {
        let root = URL(fileURLWithPath: "/Users/Till/Projects")
        let deep = URL(fileURLWithPath: "/Users/Till/Projects/26 - Routing Lab/docs")
        XCTAssertEqual(names(ColumnChain.columns(from: root, to: deep)),
                       ["Projects", "26 - Routing Lab", "docs"])
    }

    /// Standing on the anchor itself is one column, not zero.
    func testTheAnchorAloneIsOneColumn() {
        let root = URL(fileURLWithPath: "/Users/Till/Projects")
        XCTAssertEqual(names(ColumnChain.columns(from: root, to: root)), ["Projects"])
    }

    /// A stale anchor — the pane was moved somewhere else entirely — collapses to the
    /// current folder rather than showing an unrelated chain. The caller re-anchors on
    /// the next ordinary navigation.
    func testAnAnchorTheFolderIsNotUnderCollapsesToOneColumn() {
        let root = URL(fileURLWithPath: "/Users/Till/Projects")
        let elsewhere = URL(fileURLWithPath: "/Users/Till/Downloads")
        XCTAssertEqual(names(ColumnChain.columns(from: root, to: elsewhere)), ["Downloads"])
    }

    /// A sibling whose name merely *starts* with the anchor's must not be treated as
    /// inside it — component comparison, not string prefix.
    func testASimilarlyNamedSiblingIsNotInsideTheAnchor() {
        let root = URL(fileURLWithPath: "/Users/Till/Projects")
        let sibling = URL(fileURLWithPath: "/Users/Till/Projects-old/thing")
        XCTAssertEqual(names(ColumnChain.columns(from: root, to: sibling)), ["thing"])
    }

    /// Going *above* the anchor is a move out of the subtree, so it collapses too.
    func testAFolderAboveTheAnchorCollapsesToOneColumn() {
        let root = URL(fileURLWithPath: "/Users/Till/Projects")
        XCTAssertEqual(names(ColumnChain.columns(from: root, to: URL(fileURLWithPath: "/Users/Till"))),
                       ["Till"])
    }

    /// The root anchor still yields the full chain — the old behaviour, kept for
    /// `columns(for:)` and for a pane that really is at `/`.
    func testARootAnchorStillYieldsTheWholeChain() {
        XCTAssertEqual(names(ColumnChain.columns(for: URL(fileURLWithPath: "/Users/Till"))),
                       ["/", "Users", "Till"])
    }

    // MARK: - Derived selection

    /// What is highlighted in an ancestor column is the child that leads onward.
    /// Nothing stores it.
    func testAnAncestorColumnHighlightsTheChildThatLeadsOnward() {
        let chain = ColumnChain.columns(for: URL(fileURLWithPath: "/Users/Till/Projects"))
        XCTAssertEqual(ColumnChain.selectedChild(inColumnAt: 1, chain: chain)?.lastPathComponent,
                       "Till")
    }

    /// The last column has no successor — its selection is the user's own.
    func testTheLastColumnHasNoDerivedSelection() {
        let chain = ColumnChain.columns(for: URL(fileURLWithPath: "/Users/Till"))
        XCTAssertNil(ColumnChain.selectedChild(inColumnAt: chain.count - 1, chain: chain))
    }

    func testAnOutOfRangeColumnHasNoDerivedSelection() {
        let chain = ColumnChain.columns(for: URL(fileURLWithPath: "/Users"))
        XCTAssertNil(ColumnChain.selectedChild(inColumnAt: 99, chain: chain))
        XCTAssertNil(ColumnChain.selectedChild(inColumnAt: -1, chain: chain))
    }

    // MARK: - Which mode comes back (the precedence that would fail silently)

    /// The one that matters: a column pane persists `briefColumns: nil`, and the old
    /// rule maps nil to `.table`. If the name didn't win, every column browser would
    /// quietly return as a table and nothing would report an error.
    func testTheNamedModeWinsOverTheBriefColumnCount() {
        XCTAssertEqual(DisplayMode.from(persistedName: "columns", briefColumns: nil), .columns)
    }

    /// Pre-91 snapshots carry no name at all and must decode exactly as before.
    func testASnapshotWithoutANameFallsBackToTheColumnCount() {
        XCTAssertEqual(DisplayMode.from(persistedName: nil, briefColumns: 2), .brief(columns: 2))
        XCTAssertEqual(DisplayMode.from(persistedName: nil, briefColumns: nil), .table)
    }

    func testBriefRestoresItsColumnCount() {
        XCTAssertEqual(DisplayMode.from(persistedName: "brief", briefColumns: 3), .brief(columns: 3))
    }

    /// A name from a newer build must open a working pane, not a broken one — the same
    /// tolerance `RestorePath` applies to folders.
    func testAnUnknownNameDegradesToTheTable() {
        XCTAssertEqual(DisplayMode.from(persistedName: "gallery", briefColumns: nil), .table)
    }

    /// Out-of-range counts were already clamped away in #37; that must survive the new
    /// precedence rule sitting in front of it.
    func testAnOutOfRangeColumnCountStillDegradesToTheTable() {
        XCTAssertEqual(DisplayMode.from(persistedName: "brief", briefColumns: 9), .table)
    }

    /// Round-trip: what a pane writes is what it reads back, for all three modes.
    func testEveryModeRoundTrips() {
        for mode in [DisplayMode.table, .brief(columns: 3), .columns] {
            let restored = DisplayMode.from(persistedName: mode.persistedName,
                                            briefColumns: mode.briefColumns)
            XCTAssertEqual(restored, mode, "\(mode) did not survive the round trip")
        }
    }
}
