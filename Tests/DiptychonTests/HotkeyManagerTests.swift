import XCTest
@testable import Diptychon

/// Issue 44: the customizable-keymap logic — Codable round-trip, effective-map
/// resolution (defaults + overrides), steal-and-unbind, clear/reset, locked actions,
/// and persistence. All isolated to a throwaway `UserDefaults` suite; no UI, no NSEvent.
final class HotkeyManagerTests: XCTestCase {

    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "test.hotkeys.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeManager() -> HotkeyManager { HotkeyManager(defaults: defaults) }

    // Default bindings used across tests.
    private let renameDefault = KeyChord(.character("r"), command: true)  // ⌘R
    private let unusedChord = KeyChord(.character("y"), command: true)    // ⌘Y (free)

    // MARK: Codable

    func testKeyChordRoundTripCharacter() throws {
        let chord = KeyChord(.character("r"), command: true, shift: true)
        let data = try JSONEncoder().encode(chord)
        XCTAssertEqual(try JSONDecoder().decode(KeyChord.self, from: data), chord)
    }

    func testKeyChordRoundTripCode() throws {
        let chord = KeyChord(.code(123), command: true, option: true)  // ⌥⌘←
        let data = try JSONEncoder().encode(chord)
        XCTAssertEqual(try JSONDecoder().decode(KeyChord.self, from: data), chord)
    }

    func testOverrideRoundTrip() throws {
        for override in [HotkeyOverride.rebind(unusedChord), .unbound] {
            let data = try JSONEncoder().encode(override)
            XCTAssertEqual(try JSONDecoder().decode(HotkeyOverride.self, from: data), override)
        }
    }

    // MARK: Effective map

    func testNoOverridesReturnsDefault() {
        let mgr = makeManager()
        XCTAssertEqual(mgr.chord(for: .rename), renameDefault)
        XCTAssertFalse(mgr.isOverridden(.rename))
    }

    func testRebindChangesEffectiveChordAndDropsOld() {
        let mgr = makeManager()
        mgr.rebind(.rename, to: unusedChord)
        XCTAssertEqual(mgr.chord(for: .rename), unusedChord)
        XCTAssertTrue(mgr.isOverridden(.rename))
        // The old default chord no longer resolves to rename.
        XCTAssertNil(mgr.effectiveMap.first { $0.chord == renameDefault && $0.action == .rename })
    }

    func testClearUnbinds() {
        let mgr = makeManager()
        mgr.clear(.rename)
        XCTAssertNil(mgr.chord(for: .rename))
        XCTAssertTrue(mgr.isOverridden(.rename))
    }

    func testResetRestoresDefaults() {
        let mgr = makeManager()
        mgr.rebind(.rename, to: unusedChord)
        mgr.clear(.duplicate)
        mgr.reset()
        XCTAssertEqual(mgr.chord(for: .rename), renameDefault)
        XCTAssertNotNil(mgr.chord(for: .duplicate))
        XCTAssertTrue(mgr.overrides.isEmpty)
    }

    // MARK: Steal-and-unbind

    func testAssigningAnOwnedChordStealsIt() {
        let mgr = makeManager()
        // revealInFinder grabs ⌘R (rename's default) — rename must lose it.
        mgr.rebind(.revealInFinder, to: renameDefault)
        XCTAssertEqual(mgr.chord(for: .revealInFinder), renameDefault)
        XCTAssertNil(mgr.chord(for: .rename))
        // Exactly one action owns ⌘R now.
        XCTAssertEqual(mgr.effectiveMap.filter { $0.chord == renameDefault }.count, 1)
    }

    // MARK: Locked actions

    func testLockedActionCannotBeRebound() {
        let mgr = makeManager()
        let before = mgr.chord(for: .switchPanel)     // Tab — locked
        mgr.rebind(.switchPanel, to: unusedChord)
        mgr.clear(.switchPanel)
        XCTAssertEqual(mgr.chord(for: .switchPanel), before)
        XCTAssertFalse(mgr.isOverridden(.switchPanel))
    }

    // MARK: Persistence

    func testOverridesSurviveReload() {
        makeManager().rebind(.rename, to: unusedChord)
        let reloaded = HotkeyManager(defaults: defaults)  // fresh instance, same store
        XCTAssertEqual(reloaded.chord(for: .rename), unusedChord)
    }

    func testUnknownActionKeyIsIgnored() throws {
        // A future/removed action name in the stored blob must not crash the load.
        let blob = ["rename": HotkeyOverride.rebind(unusedChord),
                    "someRemovedAction": .unbound]
        let byName = Dictionary(uniqueKeysWithValues: blob.map { ($0.key, $0.value) })
        defaults.set(try JSONEncoder().encode(byName), forKey: HotkeyManager.storeKey)
        let mgr = HotkeyManager(defaults: defaults)
        XCTAssertEqual(mgr.chord(for: .rename), unusedChord)  // known key applied, unknown skipped
    }
}
