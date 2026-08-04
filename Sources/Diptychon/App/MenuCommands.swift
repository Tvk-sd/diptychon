import SwiftUI

/// The seam between the menu bar and the workspace (issue 76).
///
/// Menu commands are declared on the `App` scene, but the `WorkspaceModel` and the
/// `NSEvent` monitor both live inside `WorkspaceView`. Without a seam the standard
/// Edit menu has nobody to ask, so AppKit greys Undo/Redo/Cut/Copy/Paste/Delete out
/// permanently — the menu then states the opposite of what the app can do, about the
/// very property ADR 0004 calls the core idea.
///
/// Deliberately one object with one closure rather than a general command bus: the
/// only thing the scene needs is "run this `AppAction` on the active workspace".
@MainActor
@Observable
final class MenuCommands {
    static let shared = MenuCommands()
    private init() {}

    /// Drives `.disabled` on every menu item — observable, unlike the closure.
    /// False until a workspace has connected, so the menu never offers an action
    /// that would silently do nothing.
    private(set) var isConnected = false

    @ObservationIgnored private var handler: ((AppAction) -> Void)?

    /// Called from `WorkspaceView.onAppear` — **never** from a model's `init`: SwiftUI
    /// builds and discards throwaway `@State` instances, and a discarded one would
    /// register here and then answer for a workspace that is not on screen.
    func connect(_ handler: @escaping (AppAction) -> Void) {
        self.handler = handler
        isConnected = true
    }

    func disconnect() {
        handler = nil
        isConnected = false
    }

    func run(_ action: AppAction) { handler?(action) }
}

/// One menu row for an `AppAction`.
///
/// No `.keyboardShortcut` on purpose. The `NSEvent` monitor is the keyboard authority;
/// a SwiftUI key equivalent would be a second path to the same action, and after a
/// rebind in Settings (issue 44) the menu would advertise — and fire on — a chord the
/// user no longer has. Instead the current chord is read back from `HotkeyManager` and
/// printed in the title, so the row stays truthful across rebinds and there is provably
/// only one way for a keystroke to reach the action.
struct ActionMenuItem: View {
    let action: AppAction

    var body: some View {
        Button(title) { MenuCommands.shared.run(action) }
            .disabled(!MenuCommands.shared.isConnected)
    }

    private var title: String {
        guard let glyphs = HotkeyManager.shared.glyphs(for: action) else {
            return action.displayName
        }
        return "\(action.displayName)   \(glyphs)"
    }
}
