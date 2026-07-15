import XCTest
@testable import Diptychon

/// Issue 59: the pure inclusion predicate for the sidebar's Devices section.
/// `@MainActor` because the helper lives on the `@MainActor WorkspaceModel`.
/// (The live `mountedVolumeURLs` enumeration is verified in the real app.)
@MainActor
final class DeviceVolumePredicateTests: XCTestCase {
    func testExternalFixedDiskIsIncluded() {
        // Desktop external HDD (e.g. Seagate): fixed media, neither removable
        // nor ejectable — the issue-59 case.
        XCTAssertTrue(WorkspaceModel.isDeviceVolume(
            isRootFileSystem: false, isRemovable: false, isEjectable: false,
            isInternal: false, isLocal: true))
    }

    func testRemovableUSBStickIsIncluded() {
        XCTAssertTrue(WorkspaceModel.isDeviceVolume(
            isRootFileSystem: false, isRemovable: true, isEjectable: true,
            isInternal: false, isLocal: true))
    }

    func testBootVolumeIsExcluded() {
        // Root file system wins over everything else.
        XCTAssertFalse(WorkspaceModel.isDeviceVolume(
            isRootFileSystem: true, isRemovable: false, isEjectable: false,
            isInternal: false, isLocal: true))
    }

    func testInternalDataVolumeIsExcluded() {
        XCTAssertFalse(WorkspaceModel.isDeviceVolume(
            isRootFileSystem: false, isRemovable: false, isEjectable: false,
            isInternal: true, isLocal: true))
    }

    func testNetworkShareStaysExcluded() {
        // Non-local (network share) — scoped out by issue 47 / ADR 0003.
        XCTAssertFalse(WorkspaceModel.isDeviceVolume(
            isRootFileSystem: false, isRemovable: false, isEjectable: false,
            isInternal: false, isLocal: false))
    }

    func testUnknownResourceValuesCountAsNo() {
        XCTAssertFalse(WorkspaceModel.isDeviceVolume(
            isRootFileSystem: nil, isRemovable: nil, isEjectable: nil,
            isInternal: nil, isLocal: nil))
    }
}
