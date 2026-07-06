import AppKit

/// One runnable entry in the command palette (issue 19). Drives off the same
/// `AppAction` / model mutations as the chords and toolbar — one implementation,
/// three entry points (chord, toolbar, palette), so behaviour can't drift.
struct PaletteCommand: Identifiable {
    let id: String
    let title: String
    let category: String
    /// Chord glyphs (e.g. "⇧⌘R"), shown right-aligned. Nil for commands with no key.
    let shortcut: String?
    /// Whether the command applies right now (e.g. needs a selection). Disabled
    /// commands are shown greyed, not hidden — discoverability over a clean list.
    let isEnabled: @MainActor (WorkspaceModel) -> Bool
    /// Runs the command through its canonical code path.
    let run: @MainActor (WorkspaceModel) -> Void
}

/// The palette's command list + the pure fuzzy filter. The list is static; the
/// view evaluates `isEnabled(model)` per render for live greying.
enum CommandCatalog {
    // MARK: Enablement predicates
    private static let hasSelection: @MainActor (WorkspaceModel) -> Bool = { !$0.activeModel.selection.isEmpty }
    private static let selectionToOtherPanel: @MainActor (WorkspaceModel) -> Bool = {
        $0.rightPanelVisible && !$0.activeModel.selection.isEmpty
    }
    private static let hasClipboardFiles: @MainActor (WorkspaceModel) -> Bool = { _ in
        NSPasteboard.general.canReadObject(forClasses: [NSURL.self], options: nil)
    }

    // MARK: Builders
    /// An `AppAction`-backed command: runs via `perform`, glyphs from `Keymap`.
    private static func cmd(_ action: AppAction, _ title: String, _ category: String,
                            enabled: @escaping @MainActor (WorkspaceModel) -> Bool = { _ in true }) -> PaletteCommand {
        PaletteCommand(id: "\(action)", title: title, category: category,
                       shortcut: Keymap.glyphs(for: action),
                       isEnabled: enabled, run: { $0.perform(action) })
    }

    /// A UI toggle (no `AppAction`): runs the same mutation the toolbar button does.
    private static func toggle(_ id: String, _ title: String, shortcut: String?,
                               _ run: @escaping @MainActor (WorkspaceModel) -> Void) -> PaletteCommand {
        PaletteCommand(id: id, title: title, category: "View", shortcut: shortcut,
                       isEnabled: { _ in true }, run: run)
    }

    static let commands: [PaletteCommand] = [
        // Edit
        cmd(.undo, "Undo", "Edit", enabled: { $0.coordinator.canUndo }),
        cmd(.redo, "Redo", "Edit", enabled: { $0.coordinator.canRedo }),
        // File
        cmd(.newFolder, "New Folder", "File"),
        cmd(.newFile, "New File", "File"),
        cmd(.duplicate, "Duplicate", "File", enabled: hasSelection),
        cmd(.trash, "Move to Trash", "File", enabled: hasSelection),
        cmd(.rename, "Rename…", "File", enabled: hasSelection),
        cmd(.clipboardCopy, "Copy", "File", enabled: hasSelection),
        cmd(.paste, "Paste", "File", enabled: hasClipboardFiles),
        cmd(.pasteMove, "Paste (Move)", "File", enabled: hasClipboardFiles),
        cmd(.copyToInactive, "Copy to Other Panel", "File", enabled: selectionToOtherPanel),
        cmd(.moveToInactive, "Move to Other Panel", "File", enabled: selectionToOtherPanel),
        // Selection
        cmd(.selectAll, "Select All", "Selection"),
        cmd(.selectNone, "Deselect All", "Selection", enabled: hasSelection),
        cmd(.invertSelection, "Invert Selection", "Selection"),
        cmd(.copyPaths, "Copy Path", "Selection", enabled: hasSelection),
        cmd(.showTags, "Tags…", "Selection", enabled: hasSelection),
        // Open
        cmd(.openSelection, "Open", "Open", enabled: hasSelection),
        cmd(.openWith, "Open With…", "Open", enabled: hasSelection),
        cmd(.preview, "Quick Look", "Open", enabled: hasSelection),
        cmd(.revealInFinder, "Reveal in Finder", "Open", enabled: hasSelection),
        cmd(.showInfo, "Get Info", "Open", enabled: hasSelection),
        // View
        cmd(.toggleHidden, "Show/Hide Hidden Files", "View"),
        cmd(.focusSearch, "Search Subtree", "View"),
        cmd(.focusFilter, "Filter Folder", "View"),
        toggle("togglePreview", "Toggle Preview Pane", shortcut: "⇧⌘P") { $0.togglePreviewPane() },
        toggle("toggleStaging", "Toggle Staging Pane", shortcut: "⌘⇧B") { $0.toggleStaging() },
        cmd(.toggleSidebar, "Toggle Sidebar", "View"),
        toggle("toggleRightPanel", "Toggle Right Panel", shortcut: "⌥⌘S") { $0.rightPanelVisible.toggle() },
        // Staging (issue 20)
        cmd(.addToStaging, "Add to Staging", "Staging", enabled: hasSelection),
        cmd(.removeFromStaging, "Remove from Staging", "Staging",
            enabled: { $0.stagingFocused && !$0.stagingPanel.selection.isEmpty }),
        // Navigation
        cmd(.goUp, "Go Up", "Navigation", enabled: { $0.activeModel.canGoUp }),
        cmd(.goBack, "Back", "Navigation", enabled: { $0.activeModel.canGoBack }),
        cmd(.goForward, "Forward", "Navigation", enabled: { $0.activeModel.canGoForward }),
        cmd(.goToFolder, "Go to Folder…", "Navigation"),
        cmd(.switchPanel, "Switch Active Panel", "Navigation"),
    ]

    /// Commands whose title fuzzy-matches `query`, best match first. Empty query
    /// returns the full catalog in declared order.
    static func filter(_ query: String) -> [PaletteCommand] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return commands }
        return commands.enumerated()
            .compactMap { idx, c in fuzzyScore(trimmed, c.title).map { (c, $0, idx) } }
            .sorted { $0.1 != $1.1 ? $0.1 < $1.1 : $0.2 < $1.2 } // score asc, then declared order
            .map(\.0)
    }

    /// Subsequence fuzzy score: every char of `query` must appear in `title` in
    /// order (case-insensitive). Lower is better — rewards an early first match and
    /// few gaps. Returns nil when there's no match.
    static func fuzzyScore(_ query: String, _ title: String) -> Int? {
        let q = Array(query.lowercased())
        let t = Array(title.lowercased())
        guard !q.isEmpty else { return 0 }
        var qi = 0, firstIndex: Int? = nil, lastMatch = -1, gaps = 0
        for (ti, ch) in t.enumerated() where qi < q.count && ch == q[qi] {
            if firstIndex == nil { firstIndex = ti } else { gaps += ti - lastMatch - 1 }
            lastMatch = ti
            qi += 1
        }
        guard qi == q.count else { return nil }
        return (firstIndex ?? 0) + gaps
    }
}

// MARK: - Chord glyphs (data-driven from Keymap, so palette ↔ keymap never drift)

extension Keymap {
    /// The first chord bound to `action` in the default keymap, if any.
    static func chord(for action: AppAction) -> KeyChord? {
        `default`.first { $0.action == action }?.chord
    }
    /// `action`'s chord rendered as glyphs (e.g. "⇧⌘R"), or nil if unbound.
    static func glyphs(for action: AppAction) -> String? {
        chord(for: action).map(\.glyphs)
    }
}

extension KeyChord {
    /// Canonical menu-style glyph string: modifiers in ⌃⌥⇧⌘ order, then the key.
    var glyphs: String {
        var s = ""
        if control { s += "⌃" }
        if option { s += "⌥" }
        if shift { s += "⇧" }
        if command { s += "⌘" }
        switch trigger {
        case .character(let c): s += String(c).uppercased()
        case .code(let code): s += KeyChord.codeGlyph(code)
        }
        return s
    }

    /// Glyph for a hardware key code (the layout-independent keys the keymap uses).
    static func codeGlyph(_ code: UInt16) -> String {
        switch code {
        case 36: return "↩"
        case 48: return "⇥"
        case 49: return "␣"
        case 51: return "⌫"
        case 53: return "⎋"
        case 47: return "."
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return "?"
        }
    }
}
