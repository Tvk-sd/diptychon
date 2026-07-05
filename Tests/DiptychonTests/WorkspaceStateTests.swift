import XCTest
@testable import Diptychon

/// Issue 41: the pure snapshot layer — Codable round-trip, tolerant/versioned decode,
/// sort ↔ comparator mapping, and the trust-critical restore-path resolution. No live
/// models, no `NSWorkspace`; all IO is injected.
final class WorkspaceStateTests: XCTestCase {

    private func sample() -> WorkspaceState {
        WorkspaceState(
            left: PaneState(directoryPath: "/tmp/left", sort: PaneSort(column: .name, ascending: true)),
            right: PaneState(directoryPath: "/tmp/right", sort: .default),
            splitRatio: 0.4,
            staging: ["/tmp/a", "/tmp/b"]
        )
    }

    // MARK: Encode / decode

    func testEncodeDecodeRoundTrip() throws {
        let state = sample()
        let data = try XCTUnwrap(WorkspaceStateStore.encode(state))
        XCTAssertEqual(WorkspaceStateStore.decode(data), state)
    }

    func testDecodeGarbageReturnsNil() {
        XCTAssertNil(WorkspaceStateStore.decode(Data("not json".utf8)))
    }

    func testDecodeRejectsNewerSchema() {
        // A future breaking version must degrade to defaults (nil), not be misread.
        var future = sample()
        future.schemaVersion = WorkspaceState.currentVersion + 1
        let data = try! JSONEncoder().encode(future)
        XCTAssertNil(WorkspaceStateStore.decode(data))
    }

    func testDecodeIgnoresUnknownAdditiveKeys() throws {
        // An extra key from a forward additive field (same version) must still decode.
        let json = """
        {"schemaVersion":1,
         "left":{"directoryPath":"/tmp/l","sort":{"column":"name","ascending":true}},
         "right":{"directoryPath":"/tmp/r","sort":{"column":"date","ascending":false}},
         "staging":[],
         "viewMode":"grid"}
        """
        let state = try XCTUnwrap(WorkspaceStateStore.decode(Data(json.utf8)))
        XCTAssertEqual(state.left.directoryPath, "/tmp/l")
    }

    func testDecodeMissingRequiredFieldReturnsNil() {
        // No `right` pane → can't build a coherent workspace → defaults, not a crash.
        let json = """
        {"schemaVersion":1,
         "left":{"directoryPath":"/tmp/l","sort":{"column":"name","ascending":true}},
         "staging":[]}
        """
        XCTAssertNil(WorkspaceStateStore.decode(Data(json.utf8)))
    }

    func testSaveLoadThroughDefaults() {
        let defaults = UserDefaults(suiteName: "WorkspaceStateTests.\(UUID().uuidString)")!
        XCTAssertNil(WorkspaceStateStore.load(defaults))
        let state = sample()
        WorkspaceStateStore.save(state, to: defaults)
        XCTAssertEqual(WorkspaceStateStore.load(defaults), state)
    }

    // MARK: Sort mapping

    func testSortRoundTripsThroughComparators() {
        let cases: [PaneSort] = [
            PaneSort(column: .name, ascending: true),
            PaneSort(column: .kind, ascending: false),
            PaneSort(column: .date, ascending: false),
            PaneSort(column: .size, ascending: true),
        ]
        for original in cases {
            XCTAssertEqual(PaneSort(original.comparators), original)
        }
    }

    func testEmptyComparatorsFallBackToDefault() {
        XCTAssertEqual(PaneSort([]), .default)
    }

    func testDefaultSortMatchesAppDefault() {
        // App default is newest-first: dateForSort, descending.
        let appDefault = [KeyPathComparator(\FileItem.dateForSort, order: .reverse)]
        XCTAssertEqual(PaneSort(appDefault), .default)
    }

    // MARK: Restore path resolution

    private let home = URL(fileURLWithPath: "/Users/me", isDirectory: true)

    func testResolveUsesExistingFolder() {
        let r = RestorePath.resolve(path: "/tmp/here", home: home,
                                    fileExists: { $0 == "/tmp/here" },
                                    mountedVolumeRoots: [])
        XCTAssertEqual(r, .use(URL(fileURLWithPath: "/tmp/here", isDirectory: true)))
    }

    func testResolveUnmountedVolumeIsPending() {
        // Folder on /Volumes/Ext which isn't mounted → pending, fall back to home.
        let r = RestorePath.resolve(path: "/Volumes/Ext/Photos", home: home,
                                    fileExists: { _ in false },
                                    mountedVolumeRoots: [])
        XCTAssertEqual(r, .pending(target: URL(fileURLWithPath: "/Volumes/Ext/Photos", isDirectory: true),
                                   fallback: home))
    }

    func testResolveMountedButGoneFolderDegradesToAncestor() {
        // Volume IS mounted but the subfolder is gone → nearest existing ancestor.
        let r = RestorePath.resolve(path: "/Volumes/Ext/Photos/2021", home: home,
                                    fileExists: { $0 == "/Volumes/Ext" },
                                    mountedVolumeRoots: ["/Volumes/Ext"])
        XCTAssertEqual(r, .fallback(URL(fileURLWithPath: "/Volumes/Ext", isDirectory: true)))
    }

    func testResolveLocalGoneFolderDegradesToAncestor() {
        let r = RestorePath.resolve(path: "/Users/me/Old/Deep", home: home,
                                    fileExists: { $0 == "/Users/me" },
                                    mountedVolumeRoots: [])
        XCTAssertEqual(r, .fallback(home))
    }

    func testResolveFallsBackToHomeWhenNoAncestorExists() {
        let r = RestorePath.resolve(path: "/nope/gone", home: home,
                                    fileExists: { _ in false },
                                    mountedVolumeRoots: [])
        XCTAssertEqual(r, .fallback(home))
    }

    func testVolumeRootParsing() {
        XCTAssertEqual(RestorePath.volumeRoot(of: "/Volumes/Ext/x/y"), "/Volumes/Ext")
        XCTAssertNil(RestorePath.volumeRoot(of: "/Users/me/x"))
        XCTAssertNil(RestorePath.volumeRoot(of: "/Volumes/"))
    }
}
