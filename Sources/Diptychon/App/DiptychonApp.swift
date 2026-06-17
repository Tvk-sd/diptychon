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
        // Tracer bullet (issue 01): exactly one Panel. Defaults to the user's
        // home directory; DIPTYCHON_DIR overrides it (used for the ~50k-file
        // performance check). The dual-panel layout arrives in issue 03.
        let root = PanelView(directory: .startDirectory)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Diptychon"
        window.contentMinSize = NSSize(width: 480, height: 320)
        // Use NSHostingController (via contentViewController), NOT a bare
        // NSHostingView set as contentView: the controller wires SwiftUI into the
        // window's responder chain so the views actually receive clicks/scroll.
        window.contentViewController = NSHostingController(rootView: root)
        window.setContentSize(NSSize(width: 820, height: 540)) // sensible default.
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

private extension URL {
    /// The directory the single Panel opens on: `DIPTYCHON_DIR` if set, else the
    /// current user's home directory (independent of any sandbox container).
    static var startDirectory: URL {
        if let override = ProcessInfo.processInfo.environment["DIPTYCHON_DIR"] {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    }
}
