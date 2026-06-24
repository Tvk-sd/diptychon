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
            // Issue 16: the left sidebar (places + pinned) sits outermost-left,
            // fixed width. Collapsible via ⌃⌘S / toolbar.
            if model.sidebarVisible {
                SidebarView(model: model)
                    .frame(width: 200)
                Divider()
            }
            // Issue 13: when both panels show, an HSplitView gives a draggable
            // divider. When the right panel is hidden the container is swapped for
            // the left panel alone — HSplitView can't drop a conditional child, so
            // we toggle the whole container instead.
            if model.rightPanelVisible {
                HSplitView {
                    PanelView(model: model.left, isActive: model.active == .left,
                              onDrop: { urls, folder in model.handleDrop(urls, on: model.left, targetFolder: folder) },
                              onGoToFolder: { model.active = .left; model.goingToFolder = true },
                              onPin: { model.pin($0) })
                    .frame(minWidth: 240)
                    PanelView(model: model.right, isActive: model.active == .right,
                              onDrop: { urls, folder in model.handleDrop(urls, on: model.right, targetFolder: folder) },
                              onGoToFolder: { model.active = .right; model.goingToFolder = true },
                              onPin: { model.pin($0) })
                    .frame(minWidth: 240)
                }
            } else {
                PanelView(model: model.left, isActive: true,
                          onDrop: { urls, folder in model.handleDrop(urls, on: model.left, targetFolder: folder) },
                          onGoToFolder: { model.active = .left; model.goingToFolder = true },
                          onPin: { model.pin($0) })
            }
            if model.previewVisible {
                Divider()
                PreviewPane(model: model)
                    .frame(width: 300)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    model.sidebarVisible.toggle()
                } label: {
                    Image(systemName: "sidebar.leading")
                }
                .help("Show/Hide Sidebar (⌃⌘S)")
                .accessibilityIdentifier("toggle-sidebar")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    model.rightPanelVisible.toggle()
                } label: {
                    Image(systemName: "rectangle.split.2x1")
                }
                .help("Show/Hide Right Panel (⌥⌘S)")
                .keyboardShortcut("s", modifiers: [.command, .option])
                .accessibilityIdentifier("toggle-right-panel")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    model.previewVisible.toggle()
                } label: {
                    Image(systemName: "sidebar.right")
                }
                .help("Show Preview (⇧⌘P)")
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .accessibilityIdentifier("toggle-preview")
            }
        }
        .onAppear(perform: installMonitors)
        .onDisappear(perform: removeMonitors)
        // User may have just granted access in System Settings → if a panel was
        // blocked and access is now there, re-list it (no restart, AC3).
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.recheckFullDiskAccess()
        }
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
        .sheet(item: $model.renaming) { request in
            BatchRenameSheet(
                items: request.items,
                directory: request.directory,
                onCommit: { newNames in model.commitRename(request, newNames: newNames) },
                onCancel: { model.renaming = nil }
            )
        }
        .sheet(isPresented: $model.tagging) {
            TagPickerSheet(model: model)
        }
        .sheet(isPresented: $model.goingToFolder) {
            GoToFolderSheet(model: model)
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
                // Don't steal keys while editing a text field (Filter, rename, new
                // tag): plain keys like ␣/↩/⇥ must reach the field editor.
                if event.window?.firstResponder is NSText { return event }
                return model.handleKeyDown(event) ? nil : event
            }
        }
        if mouseMonitor == nil {
            // A click activates the Panel it landed in (by window half), regardless
            // of whether the selection changed. Not consumed — the Table still
            // gets the click to select the row.
            mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
                if let contentView = event.window?.contentView {
                    let x = event.locationInWindow.x
                    // The panels occupy the space between the sidebar (left, issue
                    // 16) and the preview pane (right, issue 14); their divider sits
                    // mid-way between those edges by default. When the right panel is
                    // hidden the left panel spans that whole area.
                    let bounds = contentView.bounds
                    let leftEdge = model.sidebarVisible ? 201.0 : bounds.minX        // 200 + divider
                    let rightEdge = model.previewVisible ? bounds.maxX - 301.0 : bounds.maxX
                    let panelsMid = (leftEdge + rightEdge) / 2
                    model.active = (model.rightPanelVisible && x >= panelsMid) ? .right : .left
                }
                // Double-click opens the selected row (first click already selected
                // it). Handled here so the Table keeps native single-click select.
                if event.clickCount == 2 {
                    DispatchQueue.main.async { model.openSelection() }
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
