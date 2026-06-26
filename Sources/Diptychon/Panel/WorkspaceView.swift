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

    /// Smallest width that fits the currently-open regions, so the window grows to
    /// accommodate the preview / second panel instead of clipping the sidebar.
    private var minContentWidth: CGFloat {
        let sidebar: CGFloat = model.sidebarVisible ? 201 : 0          // 200 + divider
        let panels: CGFloat = model.rightPanelVisible ? 180 + 180 + 1 : 320
        let preview: CGFloat = model.previewVisible ? 301 : 0          // 300 + divider
        return sidebar + panels + preview
    }

    var body: some View {
        @Bindable var model = model
        content
        .background(WindowMinWidth(minWidth: minContentWidth))
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

    /// The window body: a full-width header band (app name + window/view icons),
    /// then a horizontal seam, then the column row (sidebar | top bar + panels |
    /// preview).
    ///
    /// The icons live in the full-width header — not inside a column — so the
    /// sidebar toggle keeps one fixed spot instead of jumping sides when the
    /// sidebar folds.
    @ViewBuilder
    private var content: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            headerBar
            Divider()
            columns
        }
        // Rise under the (hidden) title bar so the header sits at the very top.
        .ignoresSafeArea(.container, edges: .top)
    }

    /// Top band, same height as the search/breadcrumb row below it. Only the left
    /// cell is a colored box — filled with the sidebar's material so it reads as
    /// the sidebar's top — holding the traffic lights + sidebar toggle (right
    /// edge). It keeps a fixed width regardless of fold state, so the toggle never
    /// moves. The right cell (name + view-toggle icons) sits plain on the window.
    private var headerBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                headerIcon("sidebar.leading", help: "Show/Hide Sidebar") {
                    model.sidebarVisible.toggle()
                }
                .accessibilityIdentifier("toggle-sidebar")
            }
            .padding(.leading, 70)   // clear the traffic lights
            .padding(.trailing, 12)
            .frame(width: 200)
            .frame(maxHeight: .infinity)
            .background(sidebarSurface)

            Divider()

            HStack(spacing: 12) {
                Text("Diptychon").font(.headline)
                Spacer(minLength: 8)
                headerIcon("rectangle.split.2x1", help: "Show/Hide Right Panel (⌥⌘S)") {
                    model.rightPanelVisible.toggle()
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
                .accessibilityIdentifier("toggle-right-panel")
                headerIcon("sidebar.right", help: "Show Preview (⇧⌘P)") {
                    model.previewVisible.toggle()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .accessibilityIdentifier("toggle-preview")
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
        }
        // Match the search/breadcrumb row height below.
        .frame(height: 36)
    }

    /// The sidebar's tinted material, reused for the left header box so it reads
    /// as a continuation of the sidebar surface.
    private var sidebarSurface: some View {
        Rectangle()
            .fill(.regularMaterial)
            .overlay(Color.primary.opacity(0.045))
    }

    /// A flat header icon button — borderless, no glass capsule (unlike `.toolbar`).
    private func headerIcon(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol) }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(help)
    }

    /// The column row below the header: sidebar | (nav bar + panels) | preview,
    /// with full-height vertical seams between them.
    @ViewBuilder
    private var columns: some View {
        @Bindable var model = model
        HStack(spacing: 0) {
            // Issue 16: the left sidebar (places + pinned) sits outermost-left,
            // fixed width. Collapsible via the header toggle.
            if model.sidebarVisible {
                SidebarView(model: model)
                    .frame(width: 200)
                Divider()
            }
            VStack(spacing: 0) {
                // Up/breadcrumb/back-forward on the Active Panel, above the panels.
                TopBarView(model: model)
                Divider()
                panels
            }
            if model.previewVisible {
                Divider()
                PreviewPane(model: model)
                    .frame(width: 300)
            }
        }
    }

    /// The panel column body: both panels in an HSplitView, or the left panel alone.
    @ViewBuilder
    private var panels: some View {
        @Bindable var model = model
        // Issue 13: when both panels show, an HSplitView gives a draggable divider.
        // When the right panel is hidden the container is swapped for the left panel
        // alone — HSplitView can't drop a conditional child, so we toggle the whole
        // container instead.
        if model.rightPanelVisible {
            HSplitView {
                PanelView(model: model.left, isActive: model.active == .left,
                          onDrop: { urls, folder in model.handleDrop(urls, on: model.left, targetFolder: folder) },
                          onGoToFolder: { model.active = .left; model.goingToFolder = true },
                          onPin: { model.pin($0) },
                          onRename: { model.renameInline($0, to: $1) },
                          tableIdentifier: "panel-left")
                .frame(minWidth: 180)
                PanelView(model: model.right, isActive: model.active == .right,
                          onDrop: { urls, folder in model.handleDrop(urls, on: model.right, targetFolder: folder) },
                          onGoToFolder: { model.active = .right; model.goingToFolder = true },
                          onPin: { model.pin($0) },
                          onRename: { model.renameInline($0, to: $1) },
                          tableIdentifier: "panel-right")
                .frame(minWidth: 180)
            }
        } else {
            PanelView(model: model.left, isActive: true,
                      onDrop: { urls, folder in model.handleDrop(urls, on: model.left, targetFolder: folder) },
                      onGoToFolder: { model.active = .left; model.goingToFolder = true },
                      onPin: { model.pin($0) },
                      onRename: { model.renameInline($0, to: $1) },
                      tableIdentifier: "panel-left")
                .frame(minWidth: 320)
        }
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
                if let window = event.window, let contentView = window.contentView {
                    let x = event.locationInWindow.x
                    let bounds = contentView.bounds
                    // The unified top bar / sidebar search occupy the top band of the
                    // content (full-width divider + 36pt bar + divider). Clicks there
                    // — e.g. the Filter field — must NOT re-activate a panel by their
                    // x-position, or clicking the Filter would steal the active panel.
                    //
                    // NB: the content view is full-size (spans behind the title bar),
                    // so measure from `contentLayoutRect.maxY` — the top of the usable
                    // area BELOW the title bar — not `bounds.maxY` (the window top).
                    let topBarBand: CGFloat = 74
                    let contentTop = window.contentLayoutRect.maxY
                    let inTopBar = event.locationInWindow.y >= contentTop - topBarBand
                    // The panels occupy the space between the sidebar (left, issue 16)
                    // and the preview pane (right, issue 14). When the right panel is
                    // hidden the left panel spans that whole area.
                    let leftEdge = model.sidebarVisible ? 201.0 : bounds.minX      // 200 + divider
                    let rightEdge = model.previewVisible ? bounds.maxX - 301.0 : bounds.maxX
                    // Only clicks inside the panels re-activate a panel. Clicks in the
                    // sidebar or preview must NOT — else clicking the sidebar with the
                    // right panel active would flip to left and navigate the wrong side.
                    let inPanels = x >= leftEdge && x <= rightEdge
                    if !inTopBar && inPanels {
                        let panelsMid = (leftEdge + rightEdge) / 2
                        model.active = (model.rightPanelVisible && x >= panelsMid) ? .right : .left

                        // Double-click opens the selected row (first click already
                        // selected it). Handled here so the Table keeps native
                        // single-click select.
                        if event.clickCount == 2 {
                            DispatchQueue.main.async { model.openSelection() }
                        }
                    }
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

/// Sets the host `NSWindow.contentMinSize.width` to `minWidth` and, if the window
/// is currently narrower (a pane just opened, or a restored frame was too small),
/// grows it — clamped on-screen — so the content never overflows and clips the
/// sidebar. SwiftUI's `.frame(minWidth:)` alone can't push the window wider.
private struct WindowMinWidth: NSViewRepresentable {
    let minWidth: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator() }

    /// Holds cross-update state so `apply` is edge-triggered, not level-triggered:
    /// `setFrame` only runs when `minWidth` genuinely increased, so growing the
    /// window can't feed back into another grow (the old code looped → runaway).
    final class Coordinator {
        var lastMinWidth: CGFloat = 0
        var retriesLeft = 20            // ~2s of 0.1s retries before the window attaches
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { apply(to: view, context.coordinator) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { apply(to: nsView, context.coordinator) }
    }

    private func apply(to view: NSView, _ coordinator: Coordinator) {
        guard let window = view.window else {
            // Not attached to a window yet (early launch) — retry, but capped so a
            // never-attaching view can't spawn timers forever.
            guard coordinator.retriesLeft > 0 else { return }
            coordinator.retriesLeft -= 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { apply(to: view, coordinator) }
            return
        }
        // contentMinSize is idempotent — safe to set every pass.
        window.contentMinSize.width = minWidth

        // Only grow on a real increase (a pane opened). Update the baseline first
        // so the relayout that setFrame triggers sees no increase and stops here.
        let didIncrease = minWidth > coordinator.lastMinWidth
        coordinator.lastMinWidth = minWidth
        guard didIncrease else { return }

        let current = window.contentLayoutRect.width
        guard current < minWidth else { return }
        var frame = window.frame
        frame.size.width += (minWidth - current)
        if let visible = window.screen?.visibleFrame {
            if frame.maxX > visible.maxX { frame.origin.x = max(visible.minX, visible.maxX - frame.size.width) }
            if frame.minX < visible.minX { frame.origin.x = visible.minX }
        }
        window.setFrame(frame, display: true, animate: false)
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
