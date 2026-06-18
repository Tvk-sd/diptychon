import AppKit

/// Things the user can trigger by hotkey. Kept separate from the keys so a
/// remapping UI can be added later (PRD: hotkeys are data-driven from day 1).
enum AppAction {
    case copyToInactive
    case undo
    case redo
    case goUp
    case switchPanel
    case clipboardCopy   // ⌘C  — mark selection on the clipboard
    case paste           // ⌘V  — copy clipboard into Active Panel
    case pasteMove       // ⌥⌘V — move clipboard into Active Panel (Finder convention)
    case trash           // ⌘⌫  — move selection to Trash
    case duplicate       // ⌘D  — duplicate selection in place
    case newFolder       // ⇧⌘N
    case newFile         // ⌃⌘N (non-standard; macOS has no native new-file key)
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
    static let delete: UInt16 = 51 // ⌫ (Backspace)
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
        (KeyChord(.code(Key.tab)), .switchPanel),               // Tab switch Active Panel
        (KeyChord(.character("c"), command: true), .clipboardCopy),
        (KeyChord(.character("v"), command: true), .paste),
        (KeyChord(.character("v"), command: true, option: true), .pasteMove),
        (KeyChord(.code(Key.delete), command: true), .trash),   // ⌘⌫ to Trash
        (KeyChord(.character("d"), command: true), .duplicate),
        (KeyChord(.character("n"), command: true, shift: true), .newFolder),
        (KeyChord(.character("n"), command: true, control: true), .newFile),
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
