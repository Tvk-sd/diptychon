import AppKit
import SwiftTerm

/// The embedded terminal's shell process and the state the UI reads (issue 65).
///
/// Owns exactly one `LocalProcessTerminalView`, created on first show and kept alive
/// while the panel is toggled — closing the panel hides the terminal, it does not kill
/// the shell. A build running behind a collapsed panel keeps running.
///
/// **The shell is fixed to the folder it was opened in** (decision 2026-08-03).
/// Nothing follows the Active Panel — no auto-`cd` that would overwrite a manual one
/// or type into a running command, and no affordance that changes meaning when the
/// active side changes. Moving elsewhere is the user's `cd`, as in any terminal.
@MainActor
@Observable
final class TerminalSession: NSObject, LocalProcessTerminalViewDelegate {
    /// The live terminal view, or nil before the panel has ever been opened.
    /// Nil-until-shown keeps the shell from being spawned for users who never
    /// open the panel.
    private(set) var terminalView: DiptychonTerminalView?

    /// Where the shell is, as far as we can tell — the name bar's source.
    ///
    /// Set to the opening folder, then refined by OSC 7 (`hostCurrentDirectoryUpdate`)
    /// if the shell reports directory changes. macOS ties its stock OSC 7 emitter
    /// (`update_terminal_cwd` in `/etc/zshrc`) to `TERM_PROGRAM=Apple_Terminal`, so in
    /// *our* terminal it often never fires — the name can therefore lag behind a
    /// manual `cd`. That is why it is only ever a name, never something the app acts on.
    private(set) var shellDirectory: URL?

    /// The shell has exited (`exit`, or it crashed). Surfaced in the name bar so a
    /// silent, unresponsive terminal is explained rather than just dead.
    private(set) var shellHasExited = false

    /// Start the shell if it isn't running yet. Idempotent — reopening the panel
    /// reattaches to the existing process.
    func startIfNeeded(in folder: URL) {
        guard terminalView == nil else { return }

        let view = DiptychonTerminalView(frame: .zero)
        view.processDelegate = self
        // The terminal is a region of the window, not a black box dropped into it:
        // it takes the same background as the file lists (`controlBackgroundColor`)
        // and the same text colour as the rest of the UI. Both are dynamic system
        // colours, so light/dark follow the app without a second theme to maintain.
        view.nativeBackgroundColor = .controlBackgroundColor
        view.nativeForegroundColor = .labelColor
        view.caretColor = .controlAccentColor
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

    /// The shell's own name (`zsh`, `fish`, …) for the name bar.
    var shellName: String {
        URL(fileURLWithPath: ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh")
            .lastPathComponent
    }

    /// End the session: stop the shell and throw the contents away (issue 90).
    ///
    /// The counterpart to ⌘J, not a replacement for it. ⌘J *hides* the panel and the
    /// shell keeps running, which is what lets a long build survive a collapsed panel
    /// (issue 65) — but that left no way to say "this session is finished". The ✕ in
    /// the tab is that way.
    ///
    /// No confirmation, even with a command running (Till's call, 2026-08-27): the ✕
    /// means end it.
    ///
    /// Dropping the view is what makes the *next* open a fresh shell — `startIfNeeded`
    /// spawns again as soon as `terminalView` is nil, in whatever folder the Panel is
    /// showing then.
    func endSession() {
        resignKeyFocus()
        terminalView?.terminate()
        terminalView = nil
        shellDirectory = nil
        shellHasExited = false
        panelHostView = nil
    }

    /// Hand key focus back to the window when the panel closes. Without this the
    /// hidden terminal stays first responder and the key monitor keeps deferring to
    /// it — every hotkey would die silently after closing the panel.
    func resignKeyFocus() {
        guard let window = terminalView?.window else { return }
        window.makeFirstResponder(nil)
    }

    /// The whole terminal panel — name bar, left inset strip and terminal — as one
    /// view, so `containsClick` can answer for the panel rather than for the terminal
    /// alone. Set by `TerminalPanelView`; nil while the panel has never been shown.
    ///
    /// Weak: the view belongs to the view hierarchy, and the session outlives it every
    /// time the panel is collapsed.
    @ObservationIgnored weak var panelHostView: NSView?

    /// Whether a click landed inside the terminal panel.
    ///
    /// Hit-tested rather than measured: the Active Panel is otherwise derived from the
    /// click's x-position in the window, and the panel spans the full width of both
    /// Panels — so a click in its right half would silently flip the Active Panel (and
    /// with it the folder the terminal reports) without anything visibly moving.
    ///
    /// Issue 89: the *whole panel* counts, not just the terminal view. The 32pt name
    /// bar and the 9pt inset strip read as part of the terminal but are not inside it,
    /// so a click there used to fall through to the x-position logic.
    func containsClick(_ event: NSEvent) -> Bool {
        if let host = panelHostView, let window = host.window, window === event.window,
           host.bounds.contains(host.convert(event.locationInWindow, from: nil)) {
            return true
        }
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
