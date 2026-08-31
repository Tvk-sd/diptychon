import SwiftUI

/// One Panel: a header (path + Up + hidden toggle + filter) above the file list.
/// The model is owned by the parent `WorkspaceView`. Focus is bound to the file
/// list (`Table`) itself via `focus`/`side`, so a single click on a row both
/// activates the Panel and selects the row.
struct PanelView: View {
    let model: PanelModel
    let isActive: Bool
    /// True when this panel is the keyboard home: active AND Staging doesn't hold
    /// the operation focus. Drives the file list's first-responder claim (issue 53)
    /// — separate from `isActive`, which also paints the border while Staging is
    /// focused.
    var hasKeyFocus: Bool = true
    let onDrop: (_ urls: [URL], _ targetFolder: FileItem?) -> Void
    /// Open the Go to Folder sheet (issue 15) — owned by the workspace.
    var onGoToFolder: () -> Void = {}
    /// Pin a folder to the sidebar (issue 16) — owned by the workspace.
    var onPin: (_ folder: URL) -> Void = { _ in }
    /// Commit an inline rename (issue 11) — owned by the workspace. Returns false
    /// if rejected (collision / empty / unchanged) so the cell reverts.
    var onRename: (_ item: FileItem, _ newName: String) -> Bool = { _, _ in false }
    /// Add files to the virtual staging set (issue 20) — owned by the workspace.
    var onAddToStaging: (_ urls: [URL]) -> Void = { _ in }
    /// Activate the clicked row on double-click (issue 25): open a file / navigate a
    /// folder. Acts on the clicked row only, never the selection.
    var onActivate: (_ item: FileItem) -> Void = { _ in }
    /// Stable a11y id for this panel's file-list table (`panel-left`/`panel-right`),
    /// so UI tests can target it by id instead of a fragile positional index (issue 23).
    var tableIdentifier: String = ""

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            // Header. Navigation + breadcrumb now live in the unified top bar
            // (issue 21); each panel keeps a minimal current-folder label so both
            // panels' locations stay visible.
            HStack(spacing: 6) {
                if model.isSearching {
                    // While searching, the label reports progress / the result set
                    // instead of the folder name (issue 21 slice 3).
                    Label(model.isSearchRunning
                          ? "Searching…"
                          : "\(model.visibleItems.count) result\(model.visibleItems.count == 1 ? "" : "s")",
                          systemImage: "magnifyingglass")
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(isActive ? .primary : .secondary)
                        .layoutPriority(-1)
                } else {
                    Text(model.directory.lastPathComponent.isEmpty ? "/" : model.directory.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(isActive ? .primary : .secondary)
                        .layoutPriority(-1) // give up width first so controls never wrap
                }

                Spacer(minLength: 4)

                displayModeSwitcher

                // Icon-only toggle for hidden files (keeps the header compact when
                // the preview pane narrows the panel — no wrapping "Hidden" label).
                Button { model.showHidden.toggle() } label: {
                    Image(systemName: model.showHidden ? "eye" : "eye.slash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(model.showHidden ? Color.accentColor : Color.secondary)
                .help(model.showHidden ? "Hide hidden files" : "Show hidden files")
                .fixedSize()

                tagFilterMenu
                // Name filter now lives in the unified top bar (issue 21) and acts
                // on the Active Panel — see TopBarView.
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Content
            switch model.state {
            case .loading:
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                if model.isSearching && model.visibleItems.isEmpty {
                    if model.isSearchRunning {
                        ProgressView("Searching…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ContentUnavailableView.search(text: model.searchQueryDisplay)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else if model.displayMode == .columns {
                    // Column browser (issue 91): the pane's folder plus its ancestors,
                    // one per column. Derived from `directory`, so nothing else in the
                    // app has to know about it.
                    ColumnBrowserView(
                        model: model,
                        onDrop: onDrop,
                        onPin: onPin,
                        onAddToStaging: onAddToStaging,
                        onActivate: onActivate,
                        onRename: onRename,
                        hasKeyFocus: hasKeyFocus,
                        accessibilityID: tableIdentifier
                    )
                } else if case .brief(let columns) = model.displayMode {
                    // Brief display mode (issue 37): same visibleItems feed, same
                    // FileListView protocol — only the renderer changes.
                    BriefFileListView(
                        items: model.visibleItems,
                        selection: $model.selection,
                        sortOrder: $model.sortOrder,
                        onDrop: onDrop,
                        onPin: onPin,
                        onAddToStaging: onAddToStaging,
                        onActivate: onActivate,
                        renameRequest: model.inlineRenameRequest,
                        onRename: onRename,
                        accessibilityID: tableIdentifier
                    )
                    .briefColumns(columns)
                    .claimingKeyFocus(hasKeyFocus)
                    .highlightingTarget(model.highlightedTargetURL)
                } else {
                    PanelFileList(
                        items: model.visibleItems,
                        selection: $model.selection,
                        sortOrder: $model.sortOrder,
                        onDrop: onDrop,
                        onPin: onPin,
                        onAddToStaging: onAddToStaging,
                        onActivate: onActivate,
                        renameRequest: model.inlineRenameRequest,
                        onRename: onRename,
                        accessibilityID: tableIdentifier
                    )
                    .claimingKeyFocus(hasKeyFocus)
                    .highlightingTarget(model.highlightedTargetURL)
                }
            case .failed(let message):
                if model.accessDenied {
                    VStack(spacing: 10) {
                        Image(systemName: "lock")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary)
                        Text("Couldn't read this folder")
                            .font(.headline)
                        Text("Full Disk Access may be required to read it.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Open Full Disk Access Settings") { FullDiskAccess.openSettings() }
                            .padding(.top, 2)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentUnavailableView(
                        "Couldn't read folder",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task { model.load() }
        // Issue 86: no border overlay. The Active Panel is told apart the way Finder,
        // Mail and Xcode do it — the *selection* carries the focus. AppKit draws the
        // first responder's selection in the accent colour and everyone else's in
        // grey, for free, because the active panel's table claims first responder.
        //
        // A border marks the whole area; the selection marks the place the keyboard
        // acts on, which is the thing the user is actually asking about. The grey
        // selection left behind in the other panel doubles as a "this is where I was"
        // marker when switching back.
        //
        // The panel header already reads primary vs. secondary (above), so a panel
        // with no selection at all is still distinguishable.
    }

    /// The three display modes as three icons (issue 91). Until now the brief view was
    /// reachable only by ⌘1 or the View menu — present but invisible, the same shape of
    /// problem the reveal handler had before #54.
    ///
    /// It lives in the **panel header**, not the bottom bar: the bottom bar carries
    /// window-level toggles (sidebar, preview, terminal), while the display mode belongs
    /// to one pane. The header is the only chrome that already exists per pane, so a
    /// click there changes the thing it sits on rather than "whichever pane is active".
    ///
    /// Header clicks are already exempt from the click-to-activate logic (issue 89's
    /// top band), so pressing these can't flip the Active Panel out from under itself.
    private var displayModeSwitcher: some View {
        HStack(spacing: 2) {
            modeIcon("list.bullet", mode: .table, help: "Detailed list")
            modeIcon("rectangle.split.3x1", mode: .brief(columns: model.lastBriefColumns),
                     help: "Brief view — names in columns (⌘1)")
            modeIcon("rectangle.split.3x1.fill", mode: .columns,
                     help: "Column view — one folder per column (⌘2)")
        }
        .fixedSize()
    }

    /// One switcher icon. Accent while its mode is the current one, so the active view
    /// is readable without trying it. Sets the mode outright rather than toggling —
    /// a click should land on the mode it shows.
    private func modeIcon(_ systemName: String, mode: DisplayMode, help: String) -> some View {
        let isCurrent: Bool = {
            // The brief icon is current for any column count, not just the last one used.
            if case .brief = mode, case .brief = model.displayMode { return true }
            return model.displayMode == mode
        }()
        return Button { model.setDisplayMode(mode) } label: {
            Image(systemName: systemName)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(isCurrent ? Color.accentColor : Color.secondary)
        .help(help)
        .accessibilityIdentifier("display-mode-\(mode.persistedName)")
    }

    /// Header control to filter the Panel to a single tag (AC4). Lists the tags
    /// actually present in the folder; selecting one again clears the filter.
    @ViewBuilder
    private var tagFilterMenu: some View {
        @Bindable var model = model
        Menu {
            Button {
                model.tagFilter = nil
            } label: {
                Label("All Tags", systemImage: model.tagFilter == nil ? "checkmark" : "tag")
            }
            if !model.availableTags.isEmpty {
                Divider()
                ForEach(model.availableTags, id: \.name) { tag in
                    Button {
                        model.tagFilter = (model.tagFilter == tag.name) ? nil : tag.name
                    } label: {
                        Label {
                            Text(tag.name)
                        } icon: {
                            // A non-template NSImage swatch keeps its color in the
                            // menu (SwiftUI strips icon tint there — issue 26); the
                            // active filter shows a checkmark instead, like "All Tags".
                            if model.tagFilter == tag.name {
                                Image(systemName: "checkmark")
                            } else {
                                Image(nsImage: tag.color.menuSwatch())
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: model.tagFilter == nil ? "tag" : "tag.fill")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Filter by tag")
        .disabled(model.availableTags.isEmpty && model.tagFilter == nil)
    }
}
