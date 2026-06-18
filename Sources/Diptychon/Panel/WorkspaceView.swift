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
    @State private var mouseMonitor: Any?

    var body: some View {
        @Bindable var model = model
        HStack(spacing: 0) {
            PanelView(model: model.left, isActive: model.active == .left) { urls, folder in
                model.handleDrop(urls, on: model.left, targetFolder: folder)
            }
            Divider()
            PanelView(model: model.right, isActive: model.active == .right) { urls, folder in
                model.handleDrop(urls, on: model.right, targetFolder: folder)
            }
        }
        .onAppear(perform: installMonitors)
        .onDisappear(perform: removeMonitors)
        .confirmationDialog(
            "Items already exist in the destination",
            isPresented: Binding(get: { model.pendingWrite != nil },
                                 set: { if !$0 { model.pendingWrite = nil } }),
            presenting: model.pendingWrite
        ) { pending in
            Button("Overwrite (cannot be undone)", role: .destructive) {
                model.resolvePendingWrite(pending, resolution: .overwrite)
            }
            Button("Keep Both") { model.resolvePendingWrite(pending, resolution: .rename) }
            Button("Skip") { model.resolvePendingWrite(pending, resolution: .skip) }
            Button("Cancel", role: .cancel) { model.pendingWrite = nil }
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

    private func installMonitors() {
        if keyMonitor == nil {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                model.handleKeyDown(event) ? nil : event
            }
        }
        if mouseMonitor == nil {
            // A click activates the Panel it landed in (by window half), regardless
            // of whether the selection changed. Not consumed — the Table still
            // gets the click to select the row.
            mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
                if let contentView = event.window?.contentView {
                    let x = event.locationInWindow.x
                    model.active = x < contentView.bounds.midX ? .left : .right
                }
                // Double-click opens the selected row (first click already selected
                // it). Handled here so the Table keeps native single-click select.
                if event.clickCount == 2 {
                    DispatchQueue.main.async { model.activeModel.openSelection() }
                }
                return event
            }
        }
    }

    private func removeMonitors() {
        if let m = keyMonitor { NSEvent.removeMonitor(m) }
        if let m = mouseMonitor { NSEvent.removeMonitor(m) }
        keyMonitor = nil
        mouseMonitor = nil
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
