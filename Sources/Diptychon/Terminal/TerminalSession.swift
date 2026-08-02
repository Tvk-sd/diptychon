import AppKit
import SwiftTerm

/// The embedded terminal's shell process and the state the UI reads (issue 65).
///
/// Owns exactly one `LocalProcessTerminalView`, created on first show and kept alive
/// while the panel is toggled — closing the panel hides the terminal, it does not kill
/// the shell. A build running behind a collapsed panel keeps running.
///
/// **The shell is autonomous.** Navigating a Panel never `cd`s the shell (decision
/// 2026-08-02): an auto-`cd` would overwrite a manual `cd` and type into a running
/// command. `panelDivergesFromShell` drives a click-to-`cd` affordance instead.
@MainActor
@Observable
final class TerminalSession: NSObject, LocalProcessTerminalViewDelegate {
    /// The live terminal view, or nil before the panel has ever been opened.
    /// Nil-until-shown keeps the shell from being spawned for users who never
    /// open the panel.
    private(set) var terminalView: DiptychonTerminalView?

    /// Where we believe the shell's cwd is.
    ///
    /// Two sources, in order of trust: OSC 7 (`hostCurrentDirectoryUpdate`) if the
    /// shell emits it, otherwise our own optimistic bookkeeping from `start` / `cd`.
    /// macOS ties its stock OSC 7 emitter (`update_terminal_cwd` in `/etc/zshrc`) to
    /// `TERM_PROGRAM=Apple_Terminal`, so in *our* terminal it usually never fires —
    /// hence the fallback rather than a hard dependency on it. A manual `cd` typed by
    /// the user therefore may go unnoticed, which is why the affordance only ever
    /// *offers* a `cd` and never asserts where the shell is.
    private(set) var shellDirectory: URL?

    /// The shell has exited (`exit`, or it crashed). The panel shows a restart hint
    /// rather than a dead black rectangle.
    private(set) var shellHasExited = false

    /// Start the shell if it isn't running yet. Idempotent — reopening the panel
    /// reattaches to the existing process.
    func startIfNeeded(in folder: URL) {
        guard terminalView == nil else { return }

        let view = DiptychonTerminalView(frame: .zero)
        view.processDelegate = self
        terminalView = view
        shellDirectory = folder
        shellHasExited = false

        // The user's login shell, so aliases and prompt match the terminal they
        // already configured. `-l` because a non-login interactive shell would skip
        // the profile that defines those.
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        // `environment: nil` ⇒ SwiftTerm's own sensible defaults (TERM=xterm-256color).
        view.startProcess(executable: shell, args: ["-l"], currentDirectory: folder.path)
    }

    /// True when the active Panel is somewhere other than where we last knew the
    /// shell to be — the condition the "cd here" affordance appears under.
    func panelDiverges(from panelFolder: URL) -> Bool {
        guard let shellDirectory, terminalView != nil else { return false }
        return shellDirectory.standardizedFileURL != panelFolder.standardizedFileURL
    }

    /// Send a `cd` for the given folder. Only ever called from an explicit user
    /// action — never on navigation.
    func cd(to folder: URL) {
        guard let terminalView else { return }
        terminalView.send(txt: "cd \(Self.shellQuoted(folder.path))\n")
        shellDirectory = folder
    }

    /// Hand key focus back to the window when the panel closes. Without this the
    /// hidden terminal stays first responder and the key monitor keeps deferring to
    /// it — every hotkey would die silently after closing the panel.
    func resignKeyFocus() {
        guard let window = terminalView?.window else { return }
        window.makeFirstResponder(nil)
    }

    /// Whether a click landed inside the terminal.
    ///
    /// Hit-tested rather than measured: the Active Panel is otherwise derived from the
    /// click's x-position in the window, and the terminal spans the full width of both
    /// Panels — so a click in its right half would silently flip the Active Panel (and
    /// with it the folder the terminal reports) without anything visibly moving.
    func containsClick(_ event: NSEvent) -> Bool {
        guard let terminalView, let contentView = event.window?.contentView,
              let hit = contentView.hitTest(event.locationInWindow) else { return false }
        return hit === terminalView || hit.isDescendant(of: terminalView)
    }

    /// True while the terminal owns the keyboard — the key monitor defers to the
    /// shell instead of running a hotkey.
    var hasKeyFocus: Bool {
        guard let terminalView, let responder = terminalView.window?.firstResponder as? NSView else {
            return false
        }
        return responder === terminalView || responder.isDescendant(of: terminalView)
    }

    /// POSIX single-quote quoting: wrap in `'…'` and rewrite any embedded `'` as
    /// `'\''`. Handles spaces, umlauts, `$`, backticks and newlines alike — the
    /// paths a file manager routinely deals with.
    /// `nonisolated` because it touches nothing on the actor — the same
    /// pure-and-therefore-testable split the rest of the codebase uses
    /// (`FavoriteApps`, `GadgetSubstitution`, `SplitPane`'s layout math).
    nonisolated static func shellQuoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    // MARK: - LocalProcessTerminalViewDelegate

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        // OSC 7 carries a file:// URL; a bare path also shows up in the wild.
        guard let directory else { return }
        shellDirectory = directory.hasPrefix("file://")
            ? URL(string: directory)?.standardizedFileURL
            : URL(fileURLWithPath: directory).standardizedFileURL
    }

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        shellHasExited = true
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
}

/// A marker subclass so the global key monitor can recognise "focus is in the
/// terminal" without importing SwiftTerm's whole type hierarchy into `WorkspaceView`
/// (issue 65). Behaviour is entirely `LocalProcessTerminalView`'s.
final class DiptychonTerminalView: LocalProcessTerminalView {}
