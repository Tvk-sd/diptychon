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
            TerminalHost(session: session, panelFolder: panelFolder)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if session.shellHasExited {
                notice("Shell beendet — Panel schließen und neu öffnen startet sie neu.")
            } else if session.panelDiverges(from: panelFolder) {
                cdBar
            }
        }
    }

    /// Offers the jump, never performs it on its own. Nothing is written to the shell
    /// until this is clicked — a running command must not have a `cd` typed into it.
    private var cdBar: some View {
        Button {
            session.cd(to: panelFolder)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.turn.down.right")
                Text("Panel ist in \(panelFolder.lastPathComponent)")
                Text("cd ⏎").foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .font(.system(size: 11))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .top) { Divider() }
        .help("Die Shell in den Ordner des aktiven Panels wechseln")
        .accessibilityIdentifier("terminal-cd-here")
    }

    private func notice(_ text: String) -> some View {
        HStack {
            Text(text).font(.system(size: 11)).foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .top) { Divider() }
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
