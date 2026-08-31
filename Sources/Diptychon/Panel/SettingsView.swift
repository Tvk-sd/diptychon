import AppKit
import SwiftUI

// MARK: - Recording a chord from a key event (issue 44)

extension KeyChord {
    /// Structural / navigation keys bind by hardware code (layout-independent); Escape
    /// is excluded here — it cancels recording instead of binding.
    private static let recordableCodes: Set<UInt16> = [48, 36, 49, 51, 123, 124, 125, 126]

    /// Build a chord from a recorded key-down, or nil if the key can't be a shortcut.
    /// Letters/digits/punctuation bind by character (layout-aware); the codes above by
    /// code — mirroring how `Keymap.default` is structured so dispatch matches.
    static func recording(from event: NSEvent) -> KeyChord? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let cmd = flags.contains(.command), opt = flags.contains(.option)
        let shift = flags.contains(.shift), ctrl = flags.contains(.control)
        if recordableCodes.contains(event.keyCode) {
            return KeyChord(.code(event.keyCode), command: cmd, option: opt, shift: shift, control: ctrl)
        }
        guard let ch = event.charactersIgnoringModifiers?.lowercased().first,
              ch.isLetter || ch.isNumber || "[]./\\-=`;',".contains(ch) else { return nil }
        return KeyChord(.character(ch), command: cmd, option: opt, shift: shift, control: ctrl)
    }
}

// MARK: - Settings window (issue 44)

/// The app's Settings window (⌘,). Three tabs: the shortcut editor, the Full Disk
/// Access deep-link (relocated here from the app menu since Settings now owns ⌘,),
/// and the reveal handler switch (issue 54).
struct SettingsRootView: View {
    var body: some View {
        TabView {
            HotkeyEditorView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
            FullDiskAccessSettingsView()
                .tabItem { Label("Full Disk Access", systemImage: "externaldrive") }
            RevealHandlerSettingsView()
                .tabItem { Label("Reveal", systemImage: "doc.viewfinder") }
        }
        .frame(width: 480, height: 560)
    }
}

/// Owns the "capture the next key" state + its `NSEvent` monitor as a **reference type**
/// so the monitor closure can reliably mutate it (a SwiftUI `@State` struct captured in
/// an escaping AppKit closure goes stale — Esc-to-cancel and the rebind would silently
/// no-op). One monitor at a time, always torn down on finish/cancel/disappear.
@MainActor @Observable final class ChordRecorder {
    /// The action currently capturing a key, or nil when idle.
    private(set) var recording: AppAction?
    /// Last outcome message (conflict / steal), shown under the list.
    var notice: String?
    @ObservationIgnored private var monitor: Any?

    func begin(_ action: AppAction, manager: HotkeyManager) {
        notice = nil
        recording = action
        removeMonitor()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 { self.finish(); return nil }              // Esc cancels
            guard let chord = KeyChord.recording(from: event) else { NSSound.beep(); return nil }
            if let owner = manager.reservedOwner(of: chord) {
                self.notice = "\(chord.glyphs) is reserved by \(owner.displayName) — pick another."
                self.finish()
                return nil
            }
            let stolenFrom = manager.effectiveMap.first { $0.chord == chord && $0.action != action }?.action
            manager.rebind(action, to: chord)
            self.notice = stolenFrom.map { "\(chord.glyphs) taken from \($0.displayName)." }
            self.finish()
            return nil
        }
    }

    func cancel() { finish() }

    private func finish() {
        recording = nil
        removeMonitor()
    }

    private func removeMonitor() {
        if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
    }
}

/// Rebind / clear / reset the keymap. Reads and writes the shared `HotkeyManager`, so
/// changes take effect app-wide immediately (dispatch + palette hints).
struct HotkeyEditorView: View {
    private var manager: HotkeyManager { .shared }
    @State private var recorder = ChordRecorder()

    private var actions: [AppAction] {
        AppAction.allCases.sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        VStack(spacing: 0) {
            List(actions, id: \.self) { action in
                row(action)
            }
            Divider()
            HStack {
                Text(recorder.notice ?? "")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Button("Reset to Defaults") {
                    manager.reset()
                    recorder.cancel()
                }
            }
            .padding(12)
        }
        .onDisappear { recorder.cancel() }
    }

    @ViewBuilder
    private func row(_ action: AppAction) -> some View {
        HStack {
            Text(action.displayName)
            Spacer()
            if recorder.recording == action {
                Text("Press a shortcut…")
                    .font(.callout)
                    .foregroundStyle(.tint)
                Button("Cancel") { recorder.cancel() }
                    .buttonStyle(.borderless)
            } else if action.isRebindable {
                Text(manager.glyphs(for: action) ?? "unbound")
                    .font(.callout).monospaced()
                    .foregroundStyle(manager.chord(for: action) == nil ? .tertiary : .secondary)
                Button { recorder.begin(action, manager: manager) } label: { Image(systemName: "pencil") }
                    .buttonStyle(.borderless)
                    .help("Record a new shortcut")
                if manager.chord(for: action) != nil {
                    Button { manager.clear(action); recorder.notice = nil } label: { Image(systemName: "xmark.circle") }
                        .buttonStyle(.borderless)
                        .help("Clear this shortcut")
                }
            } else {
                Text(manager.glyphs(for: action) ?? "—")
                    .font(.callout).monospaced()
                    .foregroundStyle(.tertiary)
                Image(systemName: "lock.fill").foregroundStyle(.tertiary)
                    .help("This shortcut is reserved and can't be changed")
            }
        }
    }
}

/// Full Disk Access status + deep-link, relocated into Settings (issue 44 / issue 10).
struct FullDiskAccessSettingsView: View {
    @State private var granted = FullDiskAccess.isGranted

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: granted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(granted ? .green : .orange)
                Text(granted ? "Full Disk Access is granted." : "Full Disk Access is not granted.")
                    .font(.headline)
            }
            Text("Diptychon needs Full Disk Access to browse protected locations "
                 + "(Desktop, Documents, Downloads, and other apps' data). macOS can't "
                 + "grant this from inside the app — open System Settings and enable "
                 + "Diptychon under Privacy & Security → Full Disk Access.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open System Settings…") { FullDiskAccess.openSettings() }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { granted = FullDiskAccess.isGranted }
    }
}

/// The reveal-handler switch (issue 54): make Diptychon the app that opens when
/// something says "Show in Finder".
///
/// The receiving side has worked since merge `24f9396`; until now the only way to turn
/// it on was a Terminal command, which meant nobody who downloaded the app ever found
/// the app's strongest "it really replaces Finder" moment.
///
/// The switch reads the system on every appearance rather than remembering its own
/// answer — the setting lives outside the app and can change behind our back.
struct RevealHandlerSettingsView: View {
    @State private var state = RevealHandler.currentState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Use Diptychon when apps reveal files", isOn: Binding(
                get: { state == .diptychon },
                set: { on in
                    on ? RevealHandler.enable() : RevealHandler.disable()
                    state = RevealHandler.currentState
                }
            ))
            .font(.headline)
            .accessibilityIdentifier("reveal-handler-toggle")

            Text(statusLine)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            // Says what this does NOT do, on purpose. macOS 26 blocks folder handlers
            // at the content-type level, so promising more here would set up a
            // disappointment the app cannot fix.
            Text("This covers “Show in Finder” from other apps — a download in your "
                 + "browser, an attachment, a build output. It does not change what "
                 + "happens when you double-click a folder, and it leaves the Desktop "
                 + "and Open/Save dialogs with Finder; macOS does not allow those to "
                 + "be handed over.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // No "restart the other app" caveat here: measured on the running build
            // (2026-08-31), a flip takes effect on the very next reveal, including
            // launching Diptychon from cold. Saying otherwise would be false.

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { state = RevealHandler.currentState }
    }

    /// Names the third case out loud: another file manager may hold the setting, and
    /// calling that "off" would tell the user Finder is handling reveals when it isn't.
    private var statusLine: String {
        switch state {
        case .diptychon:
            return "Reveals open in Diptychon."
        case .systemDefault:
            return "Reveals open in Finder — the macOS default."
        case .otherApp(let bundleID):
            return "Another app currently handles reveals (\(bundleID)). "
                 + "Turning this on replaces it; turning it off restores Finder, not that app."
        }
    }
}
