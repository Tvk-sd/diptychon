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
        let aux: CGFloat = model.rightPane != .none ? 301 : 0          // preview/staging: 300 + divider
        return sidebar + panels + aux
    }

    var body: some View {
        @Bindable var model = model
        content
        .background(WindowMinWidth(minWidth: minContentWidth))
        .onAppear { installMonitors(); model.startPersistence() }
        .onDisappear(perform: removeMonitors)
        // User may have just granted access in System Settings → if a panel was
        // blocked and access is now there, re-list it (no restart, AC3).
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.windowDidBecomeActive()
        }
        .confirmationDialog(
            "Items already exist in the destination",
            isPresented: Binding(get: { model.pendingCollision != nil },
                                 set: { if !$0 { model.presentedSheet = nil } }),
            presenting: model.pendingCollision
        ) { pending in
            Button("Overwrite (cannot be undone)", role: .destructive) {
                model.resolvePendingWrite(pending, resolution: .overwrite)
            }
            Button("Keep Both") { model.resolvePendingWrite(pending, resolution: .rename) }
            Button("Skip") { model.resolvePendingWrite(pending, resolution: .skip) }
            Button("Cancel", role: .cancel) { model.presentedSheet = nil }
        } message: { pending in
            Text("\(pending.collisionCount) item(s) with the same name already exist. "
                 + "Overwriting destroys the originals and cannot be undone.")
        }
        .sheet(item: Binding(get: { model.sheetItem },
                             set: { if $0 == nil { model.presentedSheet = nil } })) { sheet in
            switch sheet {
            case .rename(let request):
                BatchRenameSheet(
                    items: request.items,
                    directory: request.directory,
                    onCommit: { newNames in model.commitRename(request, newNames: newNames) },
                    onCancel: { model.presentedSheet = nil }
                )
            case .tags:
                TagPickerSheet(model: model)
            case .goToFolder:
                GoToFolderSheet(model: model)
            case .palette:
                CommandPaletteSheet(model: model)
            case .collision:
                EmptyView() // never — collision is the dialog, filtered out by sheetItem
            }
        }
        .overlay { progressOverlay }
        .overlay(alignment: .bottom) { activityToastView }
        .animation(.spring(duration: 0.32), value: model.activityToast)
    }

    /// Transient "Undone — …" / "Redone — …" HUD (issue 18, Tier 1): floats above the
    /// bottom bar, fades itself out. Makes the otherwise-invisible undo legible.
    @ViewBuilder
    private var activityToastView: some View {
        if let toast = model.activityToast {
            HStack(spacing: 8) {
                Image(systemName: toast.systemImage)
                Text(toast.text)
            }
            .font(.callout)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08)))
            .shadow(radius: 10, y: 3)
            .padding(.bottom, 48)   // clear the 32pt bottom bar
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
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
            Divider()
            bottomBar
        }
        // Rise under the (hidden) title bar so the header sits at the very top.
        .ignoresSafeArea(.container, edges: .top)
    }

    /// Top band, same height as the search/breadcrumb row below it. Plain on the
    /// window (same black as the rest), decoupled from the sidebar tint: a
    /// traffic-light divider caps the dots into their own cell, then the recursive
    /// Search field (promoted here from the sidebar), then the seam that closes the
    /// cell (aligned with the sidebar edge when shown). The remaining width is free
    /// space, open for future displays.
    private var headerBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                // Traffic-light zone: the dots plus a gap on the right mirroring
                // the gap to the window edge on their left, capped by a divider.
                Color.clear.frame(width: 84)
                Divider()
                // Recursive Search now holds the app's prime top-left cell (was the
                // app name). Living in the header keeps it reachable when the sidebar
                // is folded. ~100px wide — the traffic lights take the left 84.
                SearchFieldView(model: model)
                    .padding(.horizontal, 12)
            }
            .frame(width: 200)
            .frame(maxHeight: .infinity)

            // Seam closing the name cell (sits on the sidebar edge when shown).
            Divider()

            // Free black space on the window — open for future displays.
            Color.clear
                .frame(maxWidth: .infinity)
        }
        // Match the search/breadcrumb row height below.
        .frame(height: 32)
    }

    /// Bottom band mirroring `headerBar`: a tinted 200px left box (the sidebar's
    /// material, reading as the sidebar's bottom) holding the sidebar toggle at
    /// its right edge, the vertical seam continuing down from the sidebar, and
    /// the two view-toggle icons pushed to the right. Same flat icon style as the
    /// header — the toggles keep their exact x-positions, just moved to the floor.
    private var bottomBar: some View {
        // Sidebar shown: toggle sits at the 200px sidebar edge. Sidebar hidden:
        // there's no edge to align to, so the toggle + its seam collapse to the
        // left corner. The bar's one even tint means nothing is orphaned.
        let folded = !model.sidebarVisible
        return HStack(spacing: 0) {
            HStack(spacing: 0) {
                if !folded { Spacer(minLength: 0) }
                headerIcon("sidebar.leading", help: "Show/Hide Sidebar (⌘B)") {
                    model.sidebarVisible.toggle()
                }
                .accessibilityIdentifier("toggle-sidebar")
            }
            .padding(.leading, folded ? 12 : 70)
            .padding(.trailing, 12)
            .frame(width: folded ? 44 : 200)
            .frame(maxHeight: .infinity)

            Divider()

            HStack(spacing: 12) {
                Spacer(minLength: 8)
                headerIcon("rectangle.split.2x1", help: "Show/Hide Right Panel (⌥⌘S)") {
                    model.rightPanelVisible.toggle()
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
                .accessibilityIdentifier("toggle-right-panel")
                headerIcon("sidebar.right", help: "Show Preview (⇧⌘P)") {
                    model.togglePreviewPane()
                }
                .foregroundStyle(model.rightPane == .preview ? Color.accentColor : .secondary)
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .accessibilityIdentifier("toggle-preview")

                // Staging toggle, set apart by a full-height seam (issue 20).
                Divider()
                headerIcon("tray.full", help: "Show Staging (⌘⇧B)") {
                    model.toggleStaging()
                }
                .foregroundStyle(model.rightPane == .staging ? Color.accentColor : .secondary)
                .accessibilityIdentifier("toggle-staging")
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
        }
        // Match the header band height and the nav row above the panels.
        .frame(height: 32)
        // Whole bar reads as the sidebar's floor — one even material, divider on top.
        .background(sidebarSurface)
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
            switch model.rightPane {
            case .none:
                EmptyView()
            case .preview:
                Divider()
                PreviewPane(model: model)
                    .frame(width: 300)
            case .staging:
                Divider()
                StagingPaneView(model: model.stagingPanel,
                                onDrop: { model.addToStaging($0) },
                                onRemove: { model.removeFromStaging($0) },
                                onClear: { model.clearStaging() })
                    .frame(width: 300)
            }
        }
    }

    /// The panel column body: both panels in an HSplitView, or the left panel alone.
    @ViewBuilder
    private var panels: some View {
        @Bindable var model = model
        // Issue 13: when both panels show, a draggable divider splits them. Issue 45:
        // `SplitPane` binds the divider fraction to `model.splitRatio` (persisted state)
        // — SwiftUI's `HSplitView` exposed no readable fraction to save/restore.
        // When the right panel is hidden the container is swapped for the left panel
        // alone (a conditional child can't be dropped from the split).
        if model.rightPanelVisible {
            SplitPane(fraction: $model.splitRatio) {
                PanelView(model: model.left, isActive: model.active == .left,
                          onDrop: { urls, folder in model.handleDrop(urls, on: model.left, targetFolder: folder) },
                          onGoToFolder: { model.active = .left; model.presentedSheet = .goToFolder },
                          onPin: { model.pin($0) },
                          onRename: { model.renameInline($0, to: $1) },
                          onAddToStaging: { model.addToStaging($0) },
                          onActivate: { model.activate($0, in: model.left) },
                          tableIdentifier: "panel-left")
            } right: {
                PanelView(model: model.right, isActive: model.active == .right,
                          onDrop: { urls, folder in model.handleDrop(urls, on: model.right, targetFolder: folder) },
                          onGoToFolder: { model.active = .right; model.presentedSheet = .goToFolder },
                          onPin: { model.pin($0) },
                          onRename: { model.renameInline($0, to: $1) },
                          onAddToStaging: { model.addToStaging($0) },
                          onActivate: { model.activate($0, in: model.right) },
                          tableIdentifier: "panel-right")
            }
        } else {
            PanelView(model: model.left, isActive: true,
                      onDrop: { urls, folder in model.handleDrop(urls, on: model.left, targetFolder: folder) },
                      onGoToFolder: { model.active = .left; model.presentedSheet = .goToFolder },
                      onPin: { model.pin($0) },
                      onRename: { model.renameInline($0, to: $1) },
                      onAddToStaging: { model.addToStaging($0) },
                      onActivate: { model.activate($0, in: model.left) },
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
                // ⌘K is the universal entry point — it opens/closes the command
                // palette even while a text field is focused (issue 19), unlike the
                // other chords. Checked before the text-field guard below.
                if case .openPalette? = HotkeyManager.shared.action(for: event) {
                    model.perform(.openPalette)
                    return nil
                }
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
                    let rightEdge = model.rightPane != .none ? bounds.maxX - 301.0 : bounds.maxX
                    // Only clicks inside the panels re-activate a panel. Clicks in the
                    // sidebar or preview must NOT — else clicking the sidebar with the
                    // right panel active would flip to left and navigate the wrong side.
                    let inPanels = x >= leftEdge && x <= rightEdge
                    if !inTopBar && inPanels {
                        let panelsMid = (leftEdge + rightEdge) / 2
                        model.active = (model.rightPanelVisible && x >= panelsMid) ? .right : .left
                        // A file-panel click takes operation focus back from Staging.
                        model.stagingFocused = false
                        // Double-click open is handled by the table's doubleAction on
                        // the clicked row (issue 25) — not here, so it can never act on
                        // a lingering multi-selection.
                    } else if !inTopBar && model.rightPane == .staging && x > rightEdge {
                        // Click in the Staging pane → it becomes the operation source.
                        model.stagingFocused = true
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

/// The recursive Search field (issue 21), promoted into the header's left cell
/// where the app name used to sit. Binds to the Active Panel's `searchQuery`, so it
/// swaps context when the active panel changes; a clear (✕) button cancels the
/// search. ⌘F focuses it via `WorkspaceModel.searchFocusRequest`. Owns its own
/// `@FocusState` so the header row stays a plain layout container.
private struct SearchFieldView: View {
    let model: WorkspaceModel
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search…", text: Binding(
                get: { model.activeModel.searchQuery },
                set: { model.activeModel.searchQuery = $0 }
            ))
            .textFieldStyle(.plain)
            .accessibilityIdentifier("sidebar-search")
            .focused($focused)
            if !model.activeModel.searchQuery.isEmpty {
                Button { model.activeModel.searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
        .onChange(of: model.searchFocusRequest) { focused = true }
    }
}
