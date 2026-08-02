import XCTest
@testable import Diptychon

/// Issue 57: terminal-app resolution for ⌘⇧T — configured-name parsing, the
/// candidate search order, and the exists-injected resolve. All pure; no
/// NSWorkspace, nothing launches. The keymap binding is asserted here too so
/// the chord can't silently vanish from `Keymap.default`.
final class TerminalLauncherTests: XCTestCase {

    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "test.terminal.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: Configured name

    func testConfiguredNameDefaultsToTerminal() {
        XCTAssertEqual(TerminalLauncher.configuredName(from: defaults), "Terminal")
    }

    func testConfiguredNameReadsOverride() {
        defaults.set("iTerm", forKey: TerminalLauncher.defaultsKey)
        XCTAssertEqual(TerminalLauncher.configuredName(from: defaults), "iTerm")
    }

    func testConfiguredNameTrimsWhitespace() {
        defaults.set("  iTerm \n", forKey: TerminalLauncher.defaultsKey)
        XCTAssertEqual(TerminalLauncher.configuredName(from: defaults), "iTerm")
    }

    func testWhitespaceOnlyOverrideFallsBackToDefault() {
        defaults.set("   ", forKey: TerminalLauncher.defaultsKey)
        XCTAssertEqual(TerminalLauncher.configuredName(from: defaults), "Terminal")
    }

    // MARK: Candidate paths

    func testBareNameSearchesStandardAppFolders() {
        let paths = TerminalLauncher.candidatePaths(for: "iTerm")
        XCTAssertEqual(Array(paths.prefix(3)), [
            "/Applications/iTerm.app",
            "/System/Applications/Utilities/iTerm.app",
            "/System/Applications/iTerm.app",
        ])
        // Home candidate is expanded, not a literal "~".
        XCTAssertEqual(paths.count, 4)
        XCTAssertTrue(paths[3].hasSuffix("/Applications/iTerm.app"))
        XCTAssertFalse(paths[3].hasPrefix("~"))
    }

    func testExplicitPathIsUsedVerbatim() {
        XCTAssertEqual(TerminalLauncher.candidatePaths(for: "/Applications/Ghostty.app"),
                       ["/Applications/Ghostty.app"])
    }

    func testExplicitPathExpandsTilde() {
        let paths = TerminalLauncher.candidatePaths(for: "~/Applications/iTerm.app")
        XCTAssertEqual(paths.count, 1)
        XCTAssertFalse(paths[0].hasPrefix("~"))
        XCTAssertTrue(paths[0].hasSuffix("/Applications/iTerm.app"))
    }

    // MARK: Resolve

    func testResolvePicksFirstExistingCandidate() {
        let url = TerminalLauncher.resolve("iTerm") { $0 == "/Applications/iTerm.app" }
        XCTAssertEqual(url, URL(fileURLWithPath: "/Applications/iTerm.app"))
    }

    func testResolveHonoursSearchOrder() {
        // Both exist → the /Applications candidate wins (it comes first).
        let url = TerminalLauncher.resolve("iTerm") { _ in true }
        XCTAssertEqual(url, URL(fileURLWithPath: "/Applications/iTerm.app"))
    }

    func testResolveReturnsNilWhenNothingExists() {
        XCTAssertNil(TerminalLauncher.resolve("NoSuchTerm") { _ in false })
    }

    func testFallbackNameResolvesSystemTerminal() {
        let terminalPath = "/System/Applications/Utilities/Terminal.app"
        let url = TerminalLauncher.resolve(TerminalLauncher.fallbackName) { $0 == terminalPath }
        XCTAssertEqual(url, URL(fileURLWithPath: terminalPath))
    }

    // MARK: Keymap

    func testDefaultKeymapBindsCommandShiftT() {
        XCTAssertEqual(Keymap.chord(for: .openInTerminal),
                       KeyChord(.character("t"), command: true, shift: true))
    }
}
