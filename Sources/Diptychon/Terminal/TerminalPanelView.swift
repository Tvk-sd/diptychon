import SwiftUI
import SwiftTerm

/// The embedded terminal panel that spans both Panels (issue 65).
///
/// Deliberately chrome-less: no tab, no header band. The only separator is the
/// `VSplitPane` hairline above it — the same 1pt `separatorColor` seam the sidebar,
/// the panels and the bottom bar use, so the terminal reads as another region of the
/// window rather than a widget bolted into it.
struct TerminalPanelView: View {
    let session: TerminalSession
    /// The Active Panel's current folder — the terminal's cwd on first open and the
    /// target the "cd" action offers.
    let panelFolder: URL

    var body: some View {
        TerminalHost(session: session, panelFolder: panelFolder)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Overlaid, not stacked: a row that appears and disappears would push the
            // terminal's contents around every time the Panel navigates.
            .overlay(alignment: .topTrailing) { statusAction }
    }

    /// Shown only when there is something to act on, so the terminal is bare in the
    /// common case.
    @ViewBuilder
    private var statusAction: some View {
        if session.shellHasExited {
            chrome {
                Label("exited", systemImage: "stop.circle")
                    .foregroundStyle(.secondary)
            }
            .help("The shell has exited. Close and reopen the panel to start a new one.")
        } else if session.panelDiverges(from: panelFolder) {
            Button { session.cd(to: panelFolder) } label: {
                chrome {
                    // The verb carries the meaning: this *performs* a directory change,
                    // it does not report which Panel is active. Without "cd" the label
                    // reads as a folder indicator.
                    Label("cd \(panelFolder.lastPathComponent)", systemImage: "arrow.turn.down.right")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .buttonStyle(.plain)
            .help("Run cd \(panelFolder.path) in the terminal")
            .accessibilityIdentifier("terminal-cd-here")
        }
    }

    /// Shared padding/legibility treatment. A slight tint keeps the label readable
    /// over whatever the shell has drawn underneath it.
    private func chrome<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .font(.system(size: 11))
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.92))
            .overlay(Rectangle().strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1))
            .padding(8)
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
