import SwiftUI
import AppKit

/// The dual-panel workspace: two Panels side by side, each navigating
/// independently. Exactly one is the Active Panel (see `/CONTEXT.md`).
///
/// Keyboard is owned entirely by an `NSEvent` monitor resolved through the
/// data-driven `Keymap` (copy / undo / redo / up / Tab), all acting on
/// `model.active`. The Active Panel is derived from the last-changed selection or
/// navigation, so a single click both selects a row (the `Table`'s job) and
/// activates its Panel — no `@FocusState` fighting the `Table`.
struct WorkspaceView: View {
    @State private var model = WorkspaceModel()
    @State private var keyMonitor: Any?

    var body: some View {
        @Bindable var model = model
        HStack(spacing: 0) {
            PanelView(model: model.left, isActive: model.active == .left)
            Divider()
            PanelView(model: model.right, isActive: model.active == .right)
        }
        .onAppear(perform: installKeyMonitor)
        .onDisappear(perform: removeKeyMonitor)
        // Active Panel follows the last interaction (selection or navigation).
        .onChange(of: model.left.selection) { model.active = .left }
        .onChange(of: model.right.selection) { model.active = .right }
        .onChange(of: model.left.directory) { model.active = .left }
        .onChange(of: model.right.directory) { model.active = .right }
        .confirmationDialog(
            "Items already exist in the destination",
            isPresented: Binding(get: { model.pendingCopy != nil },
                                 set: { if !$0 { model.pendingCopy = nil } }),
            presenting: model.pendingCopy
        ) { pending in
            Button("Overwrite (cannot be undone)", role: .destructive) {
                model.startCopy(pending, resolution: .overwrite)
            }
            Button("Keep Both") { model.startCopy(pending, resolution: .rename) }
            Button("Skip") { model.startCopy(pending, resolution: .skip) }
            Button("Cancel", role: .cancel) { model.pendingCopy = nil }
        } message: { pending in
            Text("\(pending.collisionCount) item(s) with the same name already exist. "
                 + "Overwriting destroys the originals and cannot be undone.")
        }
        .overlay { progressOverlay }
    }

    @ViewBuilder
    private var progressOverlay: some View {
        if let running = model.coordinator.running {
            ZStack {
                Color.black.opacity(0.2).ignoresSafeArea()
                VStack(spacing: 12) {
                    Text(running.title).font(.headline)
                    ProgressView(value: running.fraction)
                        .frame(width: 240)
                    Button("Cancel") { model.coordinator.cancel() }
                }
                .padding(24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            model.handleKeyDown(event) ? nil : event
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor { NSEvent.removeMonitor(m) }
        keyMonitor = nil
    }
}

extension URL {
    /// The directory both Panels open on initially: `DIPTYCHON_DIR` if set, else
    /// the current user's home directory (independent of any sandbox container).
    static var startDirectory: URL {
        if let override = ProcessInfo.processInfo.environment["DIPTYCHON_DIR"] {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    }
}
