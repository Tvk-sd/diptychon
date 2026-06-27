import AppKit

/// Things the user can trigger by hotkey. Kept separate from the keys so a
/// remapping UI can be added later (PRD: hotkeys are data-driven from day 1).
enum AppAction {
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
    case focusFilter     // ⌘F  — focus the Active Panel's Filter field
    case revealInFinder  // ⇧⌘R — reveal the selection in Finder
    case copyPaths       // ⌥⌘C — copy the selection's path(s) to the clipboard
    case showInfo        // ⌘I  — Finder "Get Info" on the selection
    case openWith        // ⌘↩  — choose an app to open the selection with
    case moveToInactive  // ⇧⌥⌘→/← — move the selection into the Inactive Panel
}

/// What identifies a key. Letters are matched by **character** (layout-aware, so
/// ⌘Z works on QWERTZ/AZERTY etc.); arrows/Tab by **hardware key code** (those
/// have no character and are layout-independent).
enum KeyTrigger {
    case character(Character)
    case code(UInt16)
}

/// A key trigger + required modifier flags.
struct KeyChord {
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
        (KeyChord(.character("["), command: true), .goBack),    // ⌘[ back (Finder convention)
        (KeyChord(.character("]"), command: true), .goForward), // ⌘] forward
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
        (KeyChord(.character("f"), command: true), .focusFilter), // ⌘F focus Filter
        (KeyChord(.character("r"), command: true, shift: true), .revealInFinder),  // ⇧⌘R reveal
        (KeyChord(.character("c"), command: true, option: true), .copyPaths),      // ⌥⌘C copy path
        (KeyChord(.character("i"), command: true), .showInfo),   // ⌘I Get Info
        (KeyChord(.code(Key.return), command: true), .openWith), // ⌘↩ Open With
        (KeyChord(.code(Key.rightArrow), command: true, option: true, shift: true), .moveToInactive),
        (KeyChord(.code(Key.leftArrow), command: true, option: true, shift: true), .moveToInactive),
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
