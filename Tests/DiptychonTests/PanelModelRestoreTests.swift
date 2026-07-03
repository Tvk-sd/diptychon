import XCTest
@testable import Diptychon

/// Issue 41: a pane snapshots and restores its folder + sort. Restore must *not*
/// record navigation history — it's where the pane opens, not a place it navigated to.
/// `@MainActor` because `PanelModel` is; no load is triggered (we don't call `load()`).
@MainActor
final class PanelModelRestoreTests: XCTestCase {

    func testPaneStateCapturesFolderAndSort() {
        let m = PanelModel(directory: URL(fileURLWithPath: "/tmp/here", isDirectory: true))
        m.sortOrder = [KeyPathComparator(\FileItem.name, order: .forward)]
        XCTAssertEqual(m.paneState,
                       PaneState(directoryPath: "/tmp/here",
                                 sort: PaneSort(column: .name, ascending: true)))
    }

    func testRestoreSetsFolderAndSortWithoutHistory() {
        let m = PanelModel(directory: URL(fileURLWithPath: "/tmp/start", isDirectory: true))
        m.restore(directory: URL(fileURLWithPath: "/tmp/saved", isDirectory: true),
                  sort: PaneSort(column: .size, ascending: false))
        XCTAssertEqual(m.directory.path, "/tmp/saved")
        XCTAssertEqual(m.sortOrder, [KeyPathComparator(\FileItem.sizeForSort, order: .reverse)])
        // Restore is a starting point, not a navigation — no back history.
        XCTAssertFalse(m.canGoBack)
        XCTAssertFalse(m.canGoForward)
    }

    func testRelocateMovesWithoutHistory() {
        // Drive unmount relocates the pane to a fallback with no "back" to the dead dir.
        let m = PanelModel(directory: URL(fileURLWithPath: "/Volumes/Ext/Photos", isDirectory: true))
        m.relocate(to: URL(fileURLWithPath: "/Users/me", isDirectory: true))
        XCTAssertEqual(m.directory.path, "/Users/me")
        XCTAssertFalse(m.canGoBack)
    }

    func testSnapshotRestoreRoundTrip() {
        let original = PanelModel(directory: URL(fileURLWithPath: "/tmp/a", isDirectory: true))
        original.sortOrder = [KeyPathComparator(\FileItem.kind, order: .reverse)]
        let snap = original.paneState

        let restored = PanelModel(directory: URL(fileURLWithPath: "/tmp/other", isDirectory: true))
        restored.restore(directory: URL(fileURLWithPath: snap.directoryPath, isDirectory: true),
                         sort: snap.sort)
        XCTAssertEqual(restored.paneState, snap)
    }
}
