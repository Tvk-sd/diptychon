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
        // Menu commands are declared on the scene and need a workspace to act on
        // (issue 76). Connected here rather than in an init: SwiftUI discards
        // throwaway @State instances, and one of those must never answer the menu.
        .onAppear { installMonitors(); model.startPersistence(); MenuCommands.shared.connect { model.perform($0) } }
        .onDisappear { removeMonitors(); MenuCommands.shared.disconnect() }
        // Folders/files opened from outside (Dock drop, `open`, Launch Services
        // when Diptychon is the user's default folder viewer). SwiftUI's own
        // app delegate owns the odoc Apple Event and only surfaces it here —
        // an @NSApplicationDelegateAdaptor's application(_:open:) never fires.
        .onOpenURL { url in model.openExternal(url) }
        // Route external opens into this (single) window instead of spawning
        // a fresh WindowGroup window per opened folder.
        .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
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
        .overlay(alignment: .bottomLeading) { activityPanelView }
        .overlay(alignment: .bottom) { activityToastView }
        .animation(.spring(duration: 0.32), value: model.activityToast)
        .animation(.spring(duration: 0.32), value: showActivityPanel)
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

            // The Active Panel's nav row — up/back/forward + breadcrumb — lives here
            // in the true top bar, right of Search. Its trailing Spacer fills the gap
            // so the Filter cell can cap the far edge.
            TopBarView(model: model)

            // The Filter caps the trailing edge, mirroring how Search caps the left
            // and always carrying its own seam (like the sidebar toggle keeps a seam
            // even when the sidebar is folded). When an aux pane (preview/staging) is
            // open it widens to a 300px cell so the seam lines up flush with that pane
            // below; otherwise it narrows and hugs the right window edge.
            Divider()
            FilterFieldView(model: model)
                .frame(width: model.rightPane == .none ? 180 : 300)
        }
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

                // Embedded terminal toggle (issue 65). Sits with the pane toggles —
                // it opens a pane like they do.
                headerIcon("apple.terminal", help: "Show/Hide Terminal (⌘J)") {
                    model.toggleTerminal()
                }
                .foregroundStyle(model.terminalVisible ? Color.accentColor : .secondary)
                .accessibilityIdentifier("toggle-terminal")

                // Staging toggle, set apart by a full-height seam (issue 20).
                Divider()
                headerIcon("tray.full", help: "Show Staging (⌘⇧B)") {
                    model.toggleStaging()
                }
                .foregroundStyle(model.rightPane == .staging ? Color.accentColor : .secondary)
                .accessibilityIdentifier("toggle-staging")

                // Activity pane toggle (issue 34, Slice 1) — a list glyph, distinct
                // from issue 18's clock/history. Accents while pinned or an op runs.
                headerIcon("list.bullet.rectangle", help: "Show Activity") {
                    model.setActivityPanelVisible(!showActivityPanel)
                }
                .foregroundStyle(showActivityPanel ? Color.accentColor : .secondary)
                .accessibilityIdentifier("toggle-activity")
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
            // Nav (up/back/forward + breadcrumb + Filter) now lives in the header,
            // so the panels sit directly under the header divider.
            panelsWithTerminal
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

    /// The panel column with the embedded terminal below it (issue 65).
    ///
    /// The terminal wraps `panels` — not the whole `columns` row — so it spans exactly
    /// the two file Panels, which is what "over both panes" means. The sidebar and the
    /// preview/staging pane keep their full height beside it.
    @ViewBuilder
    private var panelsWithTerminal: some View {
        @Bindable var model = model
        if model.terminalVisible {
            VSplitPane(fraction: $model.terminalSplitRatio) {
                panels
            } bottom: {
                TerminalPanelView(session: model.terminal,
                                  panelFolder: model.activeModel.directory,
                                  onCloseSession: { model.closeTerminalSession() })
            }
        } else {
            panels
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
                          hasKeyFocus: model.active == .left && !model.stagingFocused,
                          onDrop: { urls, folder in model.handleDrop(urls, on: model.left, targetFolder: folder) },
                          onGoToFolder: { model.active = .left; model.presentedSheet = .goToFolder },
                          onPin: { model.pin($0) },
                          onRename: { model.renameInline($0, to: $1) },
                          onAddToStaging: { model.addToStaging($0) },
                          onActivate: { model.activate($0, in: model.left) },
                          tableIdentifier: "panel-left")
            } right: {
                PanelView(model: model.right, isActive: model.active == .right,
                          hasKeyFocus: model.active == .right && !model.stagingFocused,
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
                      hasKeyFocus: !model.stagingFocused,
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

    /// The Activity pane shows while an op is running (auto) or while the user has
    /// pinned it open (issue 34, Slice 1). Non-blocking — unlike the old modal, the
    /// rest of the UI stays live so the user can work alongside a running copy.
    /// Dismissable, not disabled: the ✕ hides the auto-shown pane for the current op
    /// (`activityPanelDismissed`); the next op surfaces it again.
    private var showActivityPanel: Bool {
        model.activityPanelVisible
    }

    @ViewBuilder
    private var activityPanelView: some View {
        if showActivityPanel {
            ActivityPanel(
                running: model.coordinator.running,
                onCancel: { model.coordinator.cancel() },
                onClose: { model.setActivityPanelVisible(false) }
            )
            .transition(.move(edge: .leading).combined(with: .opacity))
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
                // Issue 65: while the embedded terminal holds focus the shell owns the
                // keyboard — ⌘B, arrows and letter chords are all things you type at a
                // prompt. ⌘J stays live regardless, otherwise focusing the terminal
                // would leave no key to close it again.
                if model.terminal.hasKeyFocus {
                    if case .toggleTerminal? = HotkeyManager.shared.action(for: event) {
                        model.perform(.toggleTerminal)
                        return nil
                    }
                    return event
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
                // Issue 65: the terminal spans both Panels, so the x-position logic
                // below would read a click in its right half as "activate the right
                // Panel". Hit-tested, not measured — the terminal's height is dynamic.
                if model.terminal.containsClick(event) { return event }
                guard let window = event.window, let contentView = window.contentView else {
                    return event
                }
                let bounds = contentView.bounds
                // Which region the click landed in is pure geometry, so it lives in
                // `PanelClickRouter` where it can be tested without a window (issue 89).
                //
                // NB: the content view is full-size (it spans behind the title bar), so
                // the header/bottom bands are measured from `contentLayoutRect` — the
                // usable area — not from `bounds`.
                let layout = window.contentLayoutRect
                let target = PanelClickRouter.target(x: event.locationInWindow.x,
                                                     y: event.locationInWindow.y,
                                                     contentTop: layout.maxY,
                                                     contentBottom: layout.minY,
                                                     minX: bounds.minX, maxX: bounds.maxX,
                                                     sidebarVisible: model.sidebarVisible,
                                                     rightPane: model.rightPane,
                                                     rightPanelVisible: model.rightPanelVisible)
                switch target {
                case .leftPanel, .rightPanel:
                    model.active = (target == .rightPanel) ? .right : .left
                    // A file-panel click takes operation focus back from Staging.
                    model.stagingFocused = false
                    // Double-click open is handled by the table's doubleAction on the
                    // clicked row (issue 25) — not here, so it can never act on a
                    // lingering multi-selection.
                case .staging:
                    // Click in the Staging pane → it becomes the operation source.
                    model.stagingFocused = true
                case .none:
                    break
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

    /// Where the **right** Panel opens on a first launch, when there is no saved
    /// workspace to restore (issue 75).
    ///
    /// Both panels used to start on home, so the very first screen was two identical
    /// lists — the one moment the two-pane idea has to land, and it read as a
    /// rendering glitch instead. A different folder on the right shows the point
    /// without a single word of onboarding.
    ///
    /// `/Applications` rather than the obvious Documents or Downloads: those are
    /// TCC-protected, and issue 77 has the app already asking for folder access at
    /// launch. A first run that opens straight into another permission dialog is
    /// worse than two identical panels. `/Applications` is unprotected, always
    /// present, and somewhere people actually browse.
    ///
    /// `DIPTYCHON_DIR` still wins for both panes — the override means "open here,
    /// deterministically", and the UI tests rely on both panels sharing a directory.
    static var secondPaneStartDirectory: URL {
        if ProcessInfo.processInfo.environment["DIPTYCHON_DIR"] != nil { return startDirectory }
        let applications = URL(fileURLWithPath: "/Applications", isDirectory: true)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: applications.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else { return startDirectory }
        return applications
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
            // Enter on an absolute/`~` path jumps there instead of fuzzy-searching
            // (paste a path → go). Falls through to search when it isn't a path.
            .onSubmit { model.activeModel.navigateIfPath(model.activeModel.searchQuery) }
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
