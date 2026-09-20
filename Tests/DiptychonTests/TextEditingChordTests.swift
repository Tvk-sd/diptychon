import XCTest
import AppKit
@testable import Diptychon

/// Issue 95: the editing chords a focused text field must still answer after the
/// Edit menu's standard rows were replaced (issue 76). Pure table lookup, no UI.
final class TextEditingChordTests: XCTestCase {
    private func key(_ ch: String, code: UInt16 = 0, _ flags: NSEvent.ModifierFlags = []) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
                         windowNumber: 0, context: nil, characters: ch, charactersIgnoringModifiers: ch,
                         isARepeat: false, keyCode: code)!
    }

    func testCommandXCVMapToFieldEditorSelectors() {
        XCTAssertEqual(Keymap.textEditingSelector(for: key("x", .command)), #selector(NSText.cut(_:)))
        XCTAssertEqual(Keymap.textEditingSelector(for: key("c", .command)), #selector(NSText.copy(_:)))
        XCTAssertEqual(Keymap.textEditingSelector(for: key("v", .command)), #selector(NSText.paste(_:)))
    }

    func testOtherChordsAreLeftToTheField() {
        XCTAssertNil(Keymap.textEditingSelector(for: key("v")))                       // plain typing
        XCTAssertNil(Keymap.textEditingSelector(for: key("v", [.command, .option])))  // ⌥⌘V = file move
        XCTAssertNil(Keymap.textEditingSelector(for: key("c", [.command, .option])))  // ⌥⌘C = copy paths
        XCTAssertNil(Keymap.textEditingSelector(for: key("a", .command)))             // ⌘A stays on the menu
    }

    func testActionLookupUnchanged() {
        XCTAssertEqual(Keymap.action(for: key("v", .command)), .paste)
        XCTAssertEqual(Keymap.action(for: key("b", .command)), .toggleSidebar)
        XCTAssertNil(Keymap.action(for: key("v")))
    }
}
