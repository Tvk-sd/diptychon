import XCTest
@testable import Diptychon

/// Slice 2 (issue 16): pure add/remove/dedup + path round-trip for the sidebar's
/// pinned folders. No `UserDefaults` — just the list logic.
final class PinnedFoldersTests: XCTestCase {
    private let a = URL(fileURLWithPath: "/tmp/a", isDirectory: true)
    private let b = URL(fileURLWithPath: "/tmp/b", isDirectory: true)

    func testAddingAppends() {
        let result = PinnedFolders.adding(a, to: [])
        XCTAssertEqual(result.map(\.path), ["/tmp/a"])
    }

    func testAddingPreservesOrder() {
        let result = PinnedFolders.adding(b, to: [a])
        XCTAssertEqual(result.map(\.path), ["/tmp/a", "/tmp/b"])
    }

    func testAddingDedupsEquivalentPaths() {
        // A non-standard spelling of the same folder must not create a duplicate.
        let messy = URL(fileURLWithPath: "/tmp/./a", isDirectory: true)
        let result = PinnedFolders.adding(messy, to: [a])
        XCTAssertEqual(result.map(\.path), ["/tmp/a"])
    }

    func testRemoving() {
        let result = PinnedFolders.removing(a, from: [a, b])
        XCTAssertEqual(result.map(\.path), ["/tmp/b"])
    }

    func testRemovingMatchesEquivalentPaths() {
        let messy = URL(fileURLWithPath: "/tmp/./a", isDirectory: true)
        let result = PinnedFolders.removing(messy, from: [a, b])
        XCTAssertEqual(result.map(\.path), ["/tmp/b"])
    }

    func testEncodeDecodeRoundTrip() {
        let urls = [a, b]
        let decoded = PinnedFolders.decode(PinnedFolders.encode(urls))
        XCTAssertEqual(decoded.map(\.path), urls.map(\.path))
    }
}
