import XCTest
@testable import Diptychon

/// Issue 36: the store — config lives on disk (decision A), reload picks up
/// hand edits, and the first-run confirmation (decision B) persists.
@MainActor
final class GadgetStoreTests: XCTestCase {

    private var dir: URL!
    private var configURL: URL!
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() async throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("gadget-tests-\(UUID())")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        configURL = dir.appendingPathComponent("gadgets.json")
        suiteName = "gadget-store-tests-\(UUID())"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: dir)
    }

    private func write(_ json: String) throws {
        try json.data(using: .utf8)!.write(to: configURL)
    }

    private let oneGadget = """
    { "gadgets": [ { "id": "g1", "name": "One", "type": "executable", "target": "/bin/echo" } ] }
    """

    func testLoadsConfigAndReloadPicksUpHandEdits() throws {
        try write(oneGadget)
        let store = GadgetStore(configURL: configURL, defaults: defaults)
        XCTAssertEqual(store.gadgets.map(\.id), ["g1"])

        try write("""
        { "gadgets": [
            { "id": "g1", "name": "One", "type": "executable", "target": "/bin/echo" },
            { "id": "g2", "name": "Two", "type": "application", "target": "/Applications/X.app" }
        ]}
        """)
        store.reload()
        XCTAssertEqual(store.gadgets.map(\.id), ["g1", "g2"])
    }

    func testLoadErrorsSurfaceAndClearOnFix() throws {
        try write("{ broken")
        let store = GadgetStore(configURL: configURL, defaults: defaults)
        XCTAssertTrue(store.gadgets.isEmpty)
        XCTAssertFalse(store.loadErrors.isEmpty)

        try write(oneGadget)
        store.reload()
        XCTAssertEqual(store.loadErrors, [])
        XCTAssertEqual(store.gadgets.count, 1)
    }

    // MARK: First-run confirmation (decision B)

    func testExecutableNeedsConfirmationOnceAndItPersists() throws {
        try write(oneGadget)
        let store = GadgetStore(configURL: configURL, defaults: defaults)
        let gadget = store.gadgets[0]

        XCTAssertTrue(store.needsFirstRunConfirmation(gadget))
        store.markConfirmed(gadget)
        XCTAssertFalse(store.needsFirstRunConfirmation(gadget))

        // A fresh store over the same defaults (≈ app relaunch) stays confirmed.
        let relaunched = GadgetStore(configURL: configURL, defaults: defaults)
        XCTAssertFalse(relaunched.needsFirstRunConfirmation(gadget))
    }

    func testApplicationGadgetNeverNeedsConfirmation() {
        let store = GadgetStore(configURL: configURL, defaults: defaults)
        let app = Gadget(id: "a", name: "A", type: .application, target: "/Applications/X.app",
                         args: nil, workingDirectory: nil)
        XCTAssertFalse(store.needsFirstRunConfirmation(app))
    }

    // MARK: Config bootstrap

    func testEnsureConfigExistsWritesStarterOnceAndNeverOverwrites() throws {
        let store = GadgetStore(configURL: configURL, defaults: defaults)
        try store.ensureConfigExists()
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8), GadgetStore.starterConfig)

        try write(oneGadget) // user's own content…
        try store.ensureConfigExists() // …must survive a second call
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8), oneGadget)
    }
}
