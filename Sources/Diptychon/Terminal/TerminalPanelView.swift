import SwiftUI
import SwiftTerm

/// The embedded terminal panel that spans both Panels (issue 65): a 32pt name bar,
/// then the terminal.
///
/// The bar matches the header and bottom bands exactly — same height, same plain
/// window background — so the terminal reads as another region of the window. The
/// only separator is the `VSplitPane` hairline above it, the same 1pt seam used
/// everywhere else.
///
/// **The shell is fixed to the folder it was opened in.** Nothing here follows the
/// Active Panel: no target to keep in sync, no control that changes meaning when you
/// switch panes. The bar states where the shell *is*; if you want it elsewhere, you
/// `cd` — same as any terminal.
struct TerminalPanelView: View {
    let session: TerminalSession
    /// The folder the terminal opens in — read once, when the panel is first shown.
    let panelFolder: URL

    var body: some View {
        VStack(spacing: 0) {
            nameBar
            TerminalHost(session: session, panelFolder: panelFolder)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Names the session the way a terminal tab would — "<folder> — <shell>" — but
    /// without a tab's chrome: no chip, no border, just the label in the band.
    private var nameBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "apple.terminal")
            Text(session.shellHasExited
                 ? "\(folderName) — \(session.shellName) (exited)"
                 : "\(folderName) — \(session.shellName)")
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .accessibilityIdentifier("terminal-name")
    }

    /// The folder the *shell* is in. Tracked rather than assumed: a shell that reports
    /// its directory (OSC 7) after a manual `cd` updates the name, so the bar can't
    /// claim a folder the prompt has left.
    private var folderName: String {
        (session.shellDirectory ?? panelFolder).lastPathComponent
    }
}

/// Bridges the `LocalProcessTerminalView` into SwiftUI. The view is owned by the
/// session, not by this struct — SwiftUI re-creates representables freely, and a
/// re-created terminal would mean a re-spawned shell.
private struct TerminalHost: NSViewRepresentable {
    let session: TerminalSession
    let panelFolder: URL

    func makeNSView(context: Context) -> NSView {
        // Starting here rather than in the model is what pins the cwd to "the folder
        // the panel was opened from" — this runs once, on first appearance.
        session.startIfNeeded(in: panelFolder)
        let container = NSView()
        if let terminal = session.terminalView {
            terminal.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(terminal)
            NSLayoutConstraint.activate([
                terminal.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                terminal.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                terminal.topAnchor.constraint(equalTo: container.topAnchor),
                terminal.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
        }
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
