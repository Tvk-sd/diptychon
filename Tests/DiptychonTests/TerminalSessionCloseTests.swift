import XCTest
@testable import Diptychon

/// Issue 90: the ✕ in the terminal tab ends the session; ⌘J only hides the panel.
///
/// Only the state machine is covered — no shell is spawned here. What the tests pin
/// is the distinction Till asked for: two gestures, two different outcomes, and a
/// closed session that leaves nothing behind for the next open to reattach to.
@MainActor
final class TerminalSessionCloseTests: XCTestCase {

    /// ⌘J: panel away, session untouched. The reason it works this way is issue 65 —
    /// a long build has to survive a collapsed panel.
    func testTogglingTheTerminalLeavesTheSessionAlone() {
        let model = WorkspaceModel()
        // A fresh model restores the *real* last session (issue 41), so the starting
        // state is whatever the machine last saved. Say it out loud rather than
        // assuming it — the same trap as `PanelModelRestoreTests`.
        model.terminalVisible = false
        model.toggleTerminal()
        XCTAssertTrue(model.terminalVisible)
        model.toggleTerminal()
        XCTAssertFalse(model.terminalVisible)
    }

    /// The ✕: session ended *and* the panel put away. Hiding the panel is not
    /// cosmetic — it is what forces the panel to be rebuilt, so the next open spawns
    /// a fresh shell in the folder that is active then.
    func testClosingTheSessionAlsoHidesThePanel() {
        let model = WorkspaceModel()
        model.terminalVisible = true
        model.closeTerminalSession()
        XCTAssertFalse(model.terminalVisible)
    }

    /// Nothing left behind: no view to reattach to, no remembered folder, and the
    /// "(exited)" state cleared — the next session starts from zero rather than
    /// opening onto the corpse of the last one.
    func testEndingASessionClearsEverythingItLeftBehind() {
        let session = TerminalSession()
        session.endSession()
        XCTAssertNil(session.terminalView)
        XCTAssertNil(session.shellDirectory)
        XCTAssertFalse(session.shellHasExited)
    }

    /// Closing a session that was never opened must be harmless — the ✕ is only ever
    /// visible with the panel open, but nothing here may depend on that.
    func testEndingANeverStartedSessionIsHarmless() {
        let model = WorkspaceModel()
        model.terminalVisible = true
        model.closeTerminalSession()
        XCTAssertFalse(model.terminalVisible)
        XCTAssertNil(model.terminal.terminalView)
    }

    /// Ending twice must be as harmless as ending once — the ✕ is one click, but
    /// nothing here may depend on that.
    func testEndingASessionTwiceIsHarmless() {
        let session = TerminalSession()
        session.endSession()
        session.endSession()
        XCTAssertNil(session.terminalView)
    }
}
