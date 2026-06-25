import XCTest
@testable import Diptychon

/// Issue 21 slice 2: per-panel back/forward history. The stack transitions happen
/// synchronously inside the navigation methods (the directory *reload* they trigger
/// is async and irrelevant here), so we assert `directory` + `canGoBack`/
/// `canGoForward` directly. `@MainActor` because `PanelModel` is.
@MainActor
final class NavigationHistoryTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("navtest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func dir(_ name: String) throws -> URL {
        let u = root.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    func testInitialHistoryIsEmpty() {
        let m = PanelModel(directory: root)
        XCTAssertFalse(m.canGoBack)
        XCTAssertFalse(m.canGoForward)
    }

    func testGoRecordsBackHistory() throws {
        let b = try dir("b")
        let m = PanelModel(directory: root)
        m.go(to: b)
        XCTAssertEqual(m.directory, b)
        XCTAssertTrue(m.canGoBack)
        XCTAssertFalse(m.canGoForward)
    }

    func testBackAndForwardWalkTheChain() throws {
        let b = try dir("b"); let c = try dir("c")
        let m = PanelModel(directory: root)
        m.go(to: b); m.go(to: c)

        m.goBack()
        XCTAssertEqual(m.directory, b)
        XCTAssertTrue(m.canGoForward)

        m.goBack()
        XCTAssertEqual(m.directory, root)
        XCTAssertFalse(m.canGoBack)

        m.goForward()
        XCTAssertEqual(m.directory, b)
        m.goForward()
        XCTAssertEqual(m.directory, c)
        XCTAssertFalse(m.canGoForward)
    }

    func testNavigatingAfterBackClearsForward() throws {
        let b = try dir("b"); let c = try dir("c"); let d = try dir("d")
        let m = PanelModel(directory: root)
        m.go(to: b); m.go(to: c)
        m.goBack()                       // at b, forward has c
        XCTAssertTrue(m.canGoForward)

        m.go(to: d)                      // a fresh navigation drops the forward trail
        XCTAssertEqual(m.directory, d)
        XCTAssertFalse(m.canGoForward)
        XCTAssertTrue(m.canGoBack)
    }

    func testGoToCurrentDirectoryIsNoOp() {
        let m = PanelModel(directory: root)
        m.go(to: root)
        XCTAssertFalse(m.canGoBack)
    }

    func testGoBackWithEmptyHistoryIsNoOp() {
        let m = PanelModel(directory: root)
        m.goBack()
        XCTAssertEqual(m.directory, root)
        XCTAssertFalse(m.canGoBack)
    }

    func testNavigateUpRecordsHistory() throws {
        let b = try dir("b")
        let m = PanelModel(directory: b)
        m.navigateUp()
        XCTAssertEqual(m.directory.path, root.path)   // b's parent is root
        XCTAssertTrue(m.canGoBack)
        m.goBack()
        XCTAssertEqual(m.directory, b)
    }
}
