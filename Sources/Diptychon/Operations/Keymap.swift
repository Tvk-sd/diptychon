import AppKit

/// Things the user can trigger by hotkey. Kept separate from the keys so a
/// remapping UI can be added later (PRD: hotkeys are data-driven from day 1).
enum AppAction {
    case copyToInactive
    case undo
    case redo
    case goUp
    case switchPanel
}

/// A key (by hardware key code) + required modifier flags.
struct KeyChord {
    let keyCode: UInt16
    let command: Bool
    let option: Bool
    let shift: Bool
    let control: Bool

    init(_ keyCode: UInt16, command: Bool = false, option: Bool = false,
         shift: Bool = false, control: Bool = false) {
        self.keyCode = keyCode
        self.command = command
        self.option = option
        self.shift = shift
        self.control = control
    }
}

/// macOS hardware key codes we map.
private enum Key {
    static let z: UInt16 = 6
    static let tab: UInt16 = 48
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
        (KeyChord(Key.rightArrow, command: true, option: true), .copyToInactive),
        (KeyChord(Key.leftArrow, command: true, option: true), .copyToInactive),
        (KeyChord(Key.z, command: true), .undo),
        (KeyChord(Key.z, command: true, shift: true), .redo),
        (KeyChord(Key.upArrow, command: true), .goUp),       // ⌘↑ leave directory
        (KeyChord(Key.tab), .switchPanel),                   // Tab switch Active Panel
    ]

    static func action(for event: NSEvent,
                       in map: [(chord: KeyChord, action: AppAction)] = Keymap.default) -> AppAction? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        for entry in map {
            let c = entry.chord
            if event.keyCode == c.keyCode,
               flags.contains(.command) == c.command,
               flags.contains(.option) == c.option,
               flags.contains(.shift) == c.shift,
               flags.contains(.control) == c.control {
                return entry.action
            }
        }
        return nil
    }
}
