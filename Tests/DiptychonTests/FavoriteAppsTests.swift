import XCTest
@testable import Diptychon

/// Issue 28: pure add/remove/dedup + path round-trip for the Open-With menu's
/// favorite apps. No `UserDefaults` — just the list logic.
final class FavoriteAppsTests: XCTestCase {
    private let code = URL(fileURLWithPath: "/Applications/Visual Studio Code.app")
    private let sublime = URL(fileURLWithPath: "/Applications/Sublime Text.app")

    func testAddingAppends() {
        let result = FavoriteApps.adding(code, to: [])
        XCTAssertEqual(result.map(\.path), ["/Applications/Visual Studio Code.app"])
    }

    func testAddingPreservesOrder() {
        let result = FavoriteApps.adding(sublime, to: [code])
        XCTAssertEqual(result.map(\.path),
                       ["/Applications/Visual Studio Code.app", "/Applications/Sublime Text.app"])
    }

    func testAddingDedupsEquivalentPaths() {
        // A non-standard spelling of the same app must not create a duplicate.
        let messy = URL(fileURLWithPath: "/Applications/./Visual Studio Code.app")
        let result = FavoriteApps.adding(messy, to: [code])
        XCTAssertEqual(result.map(\.path), ["/Applications/Visual Studio Code.app"])
    }

    func testRemoving() {
        let result = FavoriteApps.removing(code, from: [code, sublime])
        XCTAssertEqual(result.map(\.path), ["/Applications/Sublime Text.app"])
    }

    func testRemovingMatchesEquivalentPaths() {
        let messy = URL(fileURLWithPath: "/Applications/./Visual Studio Code.app")
        let result = FavoriteApps.removing(messy, from: [code, sublime])
        XCTAssertEqual(result.map(\.path), ["/Applications/Sublime Text.app"])
    }

    func testEncodeDecodeRoundTrip() {
        let urls = [code, sublime]
        let decoded = FavoriteApps.decode(FavoriteApps.encode(urls))
        XCTAssertEqual(decoded.map(\.path), urls.map(\.path))
    }
}
