import SwiftUI

/// SwiftUI application entry point. Under a real Xcode project the SwiftUI
/// `App`/`WindowGroup` lifecycle routes input correctly, so we no longer need
/// the hand-rolled AppKit `NSWindow` + `NSHostingController` bootstrap that the
/// no-Xcode SwiftPM bundle required (see git history / ADR notes).
///
/// `WorkspaceView` owns everything itself: its `WorkspaceModel`, the `NSEvent`
/// key/mouse monitors (legit — the keyboard authority), and the initial
/// directory (`DIPTYCHON_DIR` override). So the scene is a one-liner.
@main
struct DiptychonApp: App {
    var body: some Scene {
        WindowGroup {
            WorkspaceView()
                .frame(minWidth: 720, minHeight: 360)
        }
        .defaultSize(width: 1100, height: 620)
    }
}
