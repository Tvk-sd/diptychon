import XCTest
@testable import Diptychon

/// Issue 41: the pure containment check that decides whether a pane's folder lives on
/// a volume that just mounted/unmounted. `@MainActor` because the helper lives on the
/// `@MainActor WorkspaceModel`. (The notification wiring itself is verified live.)
@MainActor
final class VolumePathTests: XCTestCase {
    func testPathUnderVolume() {
        XCTAssertTrue(WorkspaceModel.isPath("/Volumes/Ext/Photos", under: "/Volumes/Ext"))
        XCTAssertTrue(WorkspaceModel.isPath("/Volumes/Ext", under: "/Volumes/Ext"))
    }

    func testPathNotUnderVolume() {
        XCTAssertFalse(WorkspaceModel.isPath("/Volumes/External", under: "/Volumes/Ext"))
        XCTAssertFalse(WorkspaceModel.isPath("/Users/me", under: "/Volumes/Ext"))
    }

    func testTrailingSlashRootIsHandled() {
        XCTAssertTrue(WorkspaceModel.isPath("/Volumes/Ext/x", under: "/Volumes/Ext/"))
    }
}
