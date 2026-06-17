import AppKit
import SwiftUI

/// Explicit AppKit entry point. We host the SwiftUI Panel inside a real
/// `NSWindow` via `NSHostingView` rather than using the SwiftUI `App`/
/// `WindowGroup` lifecycle: under a hand-wrapped SwiftPM bundle (no Xcode), the
/// SwiftUI lifecycle produced a window that rendered but never received input.
/// This pattern gives us a normal key window with correct event routing.
/// (The whole approach reverts to a plain SwiftUI `App` once we migrate to a
/// real Xcode project.)
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dual-panel workspace (issue 03). Both Panels default to the user's home
        // directory; DIPTYCHON_DIR overrides it.
        let root = WorkspaceView()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Diptychon"
        window.contentMinSize = NSSize(width: 720, height: 360)
        // Use NSHostingController (via contentViewController), NOT a bare
        // NSHostingView set as contentView: the controller wires SwiftUI into the
        // window's responder chain so the views actually receive clicks/scroll.
        window.contentViewController = NSHostingController(rootView: root)
        window.setContentSize(NSSize(width: 1100, height: 620)) // sensible default.
        // Place on the PRIMARY display (origin .zero), not whichever screen the
        // window manager last used — avoids the window landing on an external
        // monitor / a different Space, which looks like an unresponsive window.
        let primary = NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.main
        if let vf = primary?.visibleFrame {
            let size = window.frame.size
            window.setFrameOrigin(NSPoint(x: vf.midX - size.width / 2,
                                          y: vf.midY - size.height / 2))
        }
        self.window = window

        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
