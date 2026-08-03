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

    /// Left rail shared with the file list: the terminal's first column and the name
    /// bar's icon line up with the row icons in the panels above.
    ///
    /// A measured constant, not a derived one — SwiftTerm draws its first cell at x=0
    /// with no padding API, and the table's rail comes out of `NSTableView`'s own
    /// layout rather than a value we set. Measured on the running app by pixel probe:
    /// row icons sit at x=210, and this inset puts the terminal's first glyph on the
    /// same column. If the file list's leading inset ever changes, re-measure rather
    /// than nudge by eye.
    static let contentInset: CGFloat = 9

    var body: some View {
        VStack(spacing: 0) {
            nameBar
            TerminalHost(session: session, panelFolder: panelFolder,
                         leadingInset: Self.contentInset)
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
        .padding(.leading, Self.contentInset)
        .padding(.trailing, 12)
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
    let leadingInset: CGFloat

    func makeNSView(context: Context) -> NSView {
        // Starting here rather than in the model is what pins the cwd to "the folder
        // the panel was opened from" — this runs once, on first appearance.
        session.startIfNeeded(in: panelFolder)
        let container = NSView()
        // The inset strip must not read as a gap: the container carries the terminal's
        // own background so the two are one surface.
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        if let terminal = session.terminalView {
            terminal.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(terminal)
            NSLayoutConstraint.activate([
                terminal.leadingAnchor.constraint(equalTo: container.leadingAnchor,
                                                  constant: leadingInset),
                terminal.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                terminal.topAnchor.constraint(equalTo: container.topAnchor),
                terminal.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
        }
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
