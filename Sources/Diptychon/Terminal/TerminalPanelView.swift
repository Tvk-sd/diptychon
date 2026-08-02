import SwiftUI
import SwiftTerm

/// The embedded terminal panel that spans both Panels (issue 65): the terminal itself
/// plus a "cd here" bar that appears only when the Active Panel has walked away from
/// the shell's directory.
struct TerminalPanelView: View {
    let session: TerminalSession
    /// The Active Panel's current folder — the terminal's cwd on first open and the
    /// target the "cd here" bar offers.
    let panelFolder: URL

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            TerminalHost(session: session, panelFolder: panelFolder)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Zed's terminal header: the session's identity on the left, a mini toolbar on
    /// the right. The "cd here" action lives in that toolbar rather than in a bar of
    /// its own — a full-width bar appearing under the terminal shifted the content
    /// every time you navigated, which is exactly the twitch a quiet panel shouldn't have.
    private var header: some View {
        HStack(spacing: 0) {
            titleTab
            Spacer(minLength: 8)
            toolbar
        }
        .frame(height: 28)
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    /// Reads like Zed's tab — icon plus "<folder> — <shell>". One session for now, so
    /// it is a label, not a control; a real tab strip is deferred until the tab
    /// question is answered from practice.
    private var titleTab: some View {
        HStack(spacing: 6) {
            Image(systemName: "apple.terminal")
                .font(.system(size: 11))
            Text("\(shellFolderName) — \(session.shellName)")
                .font(.system(size: 11))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .frame(maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .accessibilityIdentifier("terminal-title")
    }

    /// Right-hand mini toolbar. Empty in the common case — it only ever holds state
    /// the user needs to act on, so the header stays quiet while the shell and the
    /// Panel agree.
    @ViewBuilder
    private var toolbar: some View {
        if session.shellHasExited {
            Label("beendet", systemImage: "stop.circle")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 10)
                .help("Die Shell ist beendet. Panel schließen und neu öffnen startet sie neu.")
        } else if session.panelDiverges(from: panelFolder) {
            Button {
                session.cd(to: panelFolder)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.turn.down.right")
                    Text(panelFolder.lastPathComponent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.system(size: 11))
                .padding(.horizontal, 8)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .help("cd in \(panelFolder.path) — die Shell wechselt erst auf Klick")
            .accessibilityIdentifier("terminal-cd-here")
            .padding(.trailing, 6)
        }
    }

    /// The folder the *shell* is in, which is what the title should name — not the
    /// Panel's, or the title would claim a directory the prompt isn't in.
    private var shellFolderName: String {
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
        // Starting here rather than in the model keeps the shell tied to the panel
        // actually appearing on screen.
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
