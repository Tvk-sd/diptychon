import AppKit

/// Things the user can trigger by hotkey. Kept separate from the keys so a
/// remapping UI can be added later (PRD: hotkeys are data-driven from day 1).
/// `String` raw value gives a stable id for persisted overrides (issue 44) and a
/// `Codable`/dictionary-key for free; `CaseIterable` lets the recorder list every
/// action; `Equatable`/`Hashable` back the palette's reverse chord look-up (issue 19).
enum AppAction: String, Equatable, Hashable, CaseIterable {
    case copyToInactive
    case undo
    case redo
    case goUp
    case goBack          // ⌘[  — back in the Active Panel's history
    case goForward       // ⌘]  — forward in the Active Panel's history
    case switchPanel
    case clipboardCopy   // ⌘C  — mark selection on the clipboard
    case paste           // ⌘V  — copy clipboard into Active Panel
    case pasteMove       // ⌥⌘V — move clipboard into Active Panel (Finder convention)
    case trash           // ⌘⌫  — move selection to Trash
    case duplicate       // ⌘D  — duplicate selection in place
    case newFolder       // ⇧⌘N
    case newFile         // ⌃⌘N (non-standard; macOS has no native new-file key)
    case rename          // ⌘R  — batch-rename the selection
    case showTags        // ⌘T  — open the tag picker for the selection
    case openSelection   // ↩   — open folders (navigate) / files (default app)
    case preview         // ␣   — QuickLook the selection
    case goToFolder      // ⇧⌘G — jump the Active Panel to a typed path
    case toggleHidden    // ⌘⇧. — show/hide dotfiles in the Active Panel
    case selectAll       // ⌘A  — select every visible row
    case selectNone      // ⎋   — clear the selection (only when no modal is up)
    case invertSelection // ⌘⇧I — flip selected ↔ unselected
    case focusSearch     // ⌘F  — focus the sidebar's recursive Search field (Finder convention)
    case focusFilter     // ⌘⇧F — focus the Active Panel's Filter field
    case revealInFinder  // ⇧⌘R — reveal the selection in Finder
    case copyPaths       // ⌥⌘C — copy the selection's path(s) to the clipboard
    case showInfo        // ⌘I  — Finder "Get Info" on the selection
    case openWith        // ⌘↩  — choose an app to open the selection with
    case moveToInactive  // ⇧⌥⌘→/← — move the selection into the Inactive Panel
    case openPalette     // ⌘K  — open the command palette (issue 19)
    case addToStaging    // ⌘⇧S — add the Active selection to the staging set (issue 20)
    case toggleStaging   // ⌘⇧B — swap the Active Panel to the staging set and back (issue 20)
    case removeFromStaging // ⌫ in the Staging pane — unstage (no disk delete) (issue 20)
    case toggleSidebar   // ⌘B — show/hide the left Places sidebar (VS Code convention)
    case openInTerminal  // ⌘⇧T — open a terminal window in the Active Panel's folder (issue 57)
}

extension AppAction {
    /// Human-readable name for the shortcuts editor (issue 44).
    var displayName: String {
        switch self {
        case .copyToInactive:   return "Copy to Inactive Panel"
        case .undo:             return "Undo"
        case .redo:             return "Redo"
        case .goUp:             return "Go Up (Leave Folder)"
        case .goBack:           return "Back"
        case .goForward:        return "Forward"
        case .switchPanel:      return "Switch Active Panel"
        case .clipboardCopy:    return "Copy"
        case .paste:            return "Paste"
        case .pasteMove:        return "Paste (Move)"
        case .trash:            return "Move to Trash"
        case .duplicate:        return "Duplicate"
        case .newFolder:        return "New Folder"
        case .newFile:          return "New File"
        case .rename:           return "Rename"
        case .showTags:         return "Edit Tags"
        case .openSelection:    return "Open Selection"
        case .preview:          return "Quick Look"
        case .goToFolder:       return "Go to Folder…"
        case .toggleHidden:     return "Show Hidden Files"
        case .selectAll:        return "Select All"
        case .selectNone:       return "Clear Selection"
        case .invertSelection:  return "Invert Selection"
        case .focusSearch:      return "Focus Search"
        case .focusFilter:      return "Focus Filter"
        case .revealInFinder:   return "Reveal in Finder"
        case .copyPaths:        return "Copy Path(s)"
        case .showInfo:         return "Get Info"
        case .openWith:         return "Open With…"
        case .moveToInactive:   return "Move to Inactive Panel"
        case .openPalette:      return "Command Palette"
        case .addToStaging:     return "Add to Staging"
        case .toggleStaging:    return "Toggle Staging Panel"
        case .removeFromStaging:return "Remove from Staging"
        case .toggleSidebar:    return "Toggle Sidebar"
        case .openInTerminal:   return "Open in Terminal"
        }
    }

    /// Actions bound to bare structural keys that collide with table / first-responder
    /// behaviour (Tab, ↩, ␣, ⌫, ⎋). These stay locked in the editor — rebinding them
    /// would break navigation/open/preview/selection semantics (issue 44).
    var isRebindable: Bool {
        switch self {
        case .switchPanel, .openSelection, .preview, .selectNone, .removeFromStaging:
            return false
        default:
            return true
        }
    }
}

/// What identifies a key. Letters are matched by **character** (layout-aware, so
/// ⌘Z works on QWERTZ/AZERTY etc.); arrows/Tab by **hardware key code** (those
/// have no character and are layout-independent). `Codable` so user overrides can
/// round-trip through `UserDefaults` (issue 44) — `Character` isn't `Codable`, so
/// both cases serialize via an explicit kind + value.
enum KeyTrigger: Equatable, Codable {
    case character(Character)
    case code(UInt16)

    private enum CodingKeys: String, CodingKey { case kind, character, code }
    private enum Kind: String, Codable { case character, code }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .character(let ch):
            try c.encode(Kind.character, forKey: .kind)
            try c.encode(String(ch), forKey: .character)
        case .code(let code):
            try c.encode(Kind.code, forKey: .kind)
            try c.encode(code, forKey: .code)
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .kind) {
        case .character:
            let s = try c.decode(String.self, forKey: .character)
            guard let ch = s.first, s.count == 1 else {
                throw DecodingError.dataCorruptedError(forKey: .character, in: c,
                    debugDescription: "expected a single character, got \(s.debugDescription)")
            }
            self = .character(ch)
        case .code:
            self = .code(try c.decode(UInt16.self, forKey: .code))
        }
    }
}

/// A key trigger + required modifier flags. `Codable`/`Equatable` for persisted
/// overrides and conflict detection (issue 44).
struct KeyChord: Equatable, Codable {
    let trigger: KeyTrigger
    let command: Bool
    let option: Bool
    let shift: Bool
    let control: Bool

    init(_ trigger: KeyTrigger, command: Bool = false, option: Bool = false,
         shift: Bool = false, control: Bool = false) {
        self.trigger = trigger
        self.command = command
        self.option = option
        self.shift = shift
        self.control = control
    }
}

/// macOS hardware key codes (layout-independent keys only).
private enum Key {
    static let tab: UInt16 = 48
    static let `return`: UInt16 = 36
    static let space: UInt16 = 49
    static let delete: UInt16 = 51 // ⌫ (Backspace)
    static let escape: UInt16 = 53
    static let period: UInt16 = 47 // matched by code: ⌘⇧. yields a layout-dependent char (">", ":" …)
    static let leftArrow: UInt16 = 123
    static let rightArrow: UInt16 = 124
    static let upArrow: UInt16 = 126
}

/// The default action→key table. Lookups go through here, never hard-coded key
/// checks at the call site. Matched against `NSEvent` because a focused `Table`
/// swallows arrow keys before SwiftUI's `onKeyPress` can see them.
enum Keymap {
    static let `default`: [(chord: KeyChord, action: AppAction)] = [
        // Commander gesture: copy the Active selection into the Inactive Panel.
        // Either arrow triggers it (direction is just which side is inactive).
        (KeyChord(.code(Key.rightArrow), command: true, option: true), .copyToInactive),
        (KeyChord(.code(Key.leftArrow), command: true, option: true), .copyToInactive),
        (KeyChord(.character("z"), command: true), .undo),
        (KeyChord(.character("z"), command: true, shift: true), .redo),
        (KeyChord(.code(Key.upArrow), command: true), .goUp),   // ⌘↑ leave directory
        // History runs on ⌘←/⌘→ (Safari convention): keycode chords work on every
        // keyboard layout, unlike ⌘[/⌘] — on a German layout `[` is ⌥5, so the
        // character chord can never match. The bracket pair stays as an alias
        // for US layouts (Finder convention); first match wins in the palette.
        (KeyChord(.code(Key.leftArrow), command: true), .goBack),
        (KeyChord(.code(Key.rightArrow), command: true), .goForward),
        (KeyChord(.character("["), command: true), .goBack),
        (KeyChord(.character("]"), command: true), .goForward),
        (KeyChord(.code(Key.tab)), .switchPanel),               // Tab switch Active Panel
        (KeyChord(.character("c"), command: true), .clipboardCopy),
        (KeyChord(.character("v"), command: true), .paste),
        (KeyChord(.character("v"), command: true, option: true), .pasteMove),
        (KeyChord(.code(Key.delete), command: true), .trash),   // ⌘⌫ to Trash
        (KeyChord(.character("d"), command: true), .duplicate),
        (KeyChord(.character("n"), command: true, shift: true), .newFolder),
        (KeyChord(.character("n"), command: true, control: true), .newFile),
        (KeyChord(.character("r"), command: true), .rename),
        (KeyChord(.character("t"), command: true), .showTags),
        (KeyChord(.code(Key.return)), .openSelection),          // ↩ open folder/file
        (KeyChord(.code(Key.space)), .preview),                 // ␣ QuickLook
        (KeyChord(.character("g"), command: true, shift: true), .goToFolder),
        // Issue 28 — Marta-informed keyboard expansion (all Mac-native).
        (KeyChord(.code(Key.period), command: true, shift: true), .toggleHidden), // ⌘⇧. show hidden
        (KeyChord(.character("a"), command: true), .selectAll),  // ⌘A select all
        (KeyChord(.code(Key.escape)), .selectNone),             // ⎋ clear selection
        (KeyChord(.character("i"), command: true, shift: true), .invertSelection), // ⌘⇧I invert
        (KeyChord(.character("f"), command: true), .focusSearch), // ⌘F focus Search (Finder convention)
        (KeyChord(.character("f"), command: true, shift: true), .focusFilter), // ⌘⇧F focus Filter
        (KeyChord(.character("r"), command: true, shift: true), .revealInFinder),  // ⇧⌘R reveal
        (KeyChord(.character("c"), command: true, option: true), .copyPaths),      // ⌥⌘C copy path
        (KeyChord(.character("i"), command: true), .showInfo),   // ⌘I Get Info
        (KeyChord(.code(Key.return), command: true), .openWith), // ⌘↩ Open With
        (KeyChord(.code(Key.rightArrow), command: true, option: true, shift: true), .moveToInactive),
        (KeyChord(.code(Key.leftArrow), command: true, option: true, shift: true), .moveToInactive),
        (KeyChord(.character("k"), command: true), .openPalette), // ⌘K command palette (issue 19)
        // Issue 20 — virtual staging panel.
        (KeyChord(.character("s"), command: true, shift: true), .addToStaging),  // ⌘⇧S add to staging
        (KeyChord(.character("b"), command: true, shift: true), .toggleStaging), // ⌘⇧B show/hide staging
        (KeyChord(.code(Key.delete)), .removeFromStaging),                       // ⌫ unstage (staging pane)
        (KeyChord(.character("b"), command: true), .toggleSidebar), // ⌘B show/hide sidebar
        // Issue 57 — external terminal launch. ⌘T stays reserved for possible tabs.
        (KeyChord(.character("t"), command: true, shift: true), .openInTerminal), // ⌘⇧T terminal in Active folder
    ]

    static func action(for event: NSEvent,
                       in map: [(chord: KeyChord, action: AppAction)] = Keymap.default) -> AppAction? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        // Layout-aware character, ignoring modifiers (so ⇧ doesn't give "Z").
        let character = event.charactersIgnoringModifiers?.lowercased()

        for entry in map {
            let c = entry.chord
            guard flags.contains(.command) == c.command,
                  flags.contains(.option) == c.option,
                  flags.contains(.shift) == c.shift,
                  flags.contains(.control) == c.control
            else { continue }

            switch c.trigger {
            case .character(let ch):
                if character == String(ch) { return entry.action }
            case .code(let code):
                if event.keyCode == code { return entry.action }
            }
        }
        return nil
    }
}
