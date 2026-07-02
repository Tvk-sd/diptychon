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
    init() {
        // Earliest app-controlled instant — the cold-launch baseline start (issue 22).
        // The first panel to finish loading reports the delta to the unified log.
        Perf.launchStart = .now()
        // Right panel defaults to shown; `bool(forKey:)` then honors the persisted
        // value or a `-rightPanelVisible NO` launch arg. (Registered before the
        // WorkspaceModel reads it.)
        UserDefaults.standard.register(defaults: ["rightPanelVisible": true, "sidebarVisible": true])
    }

    var body: some Scene {
        WindowGroup {
            WorkspaceView()
                .frame(minWidth: 720, minHeight: 360)
        }
        // Wide enough that sidebar + both panels + preview can each still show the
        // Name/Size/Date columns (issue 17 narrow-panel work). Narrower windows
        // degrade gracefully: the Name column flexes and Size/Date drop off last.
        .defaultSize(width: 1280, height: 720)
        // No system title text — the app name lives in the panel column's top bar
        // (TopBarView). hiddenTitleBar also lets content rise full-height so the
        // sidebar/panel seams run up through the title-bar band.
        .windowStyle(.hiddenTitleBar)
        .commands {
            // App menu → standard Preferences slot (⌘,). FDA can't be requested
            // in code (ADR 0001); this just deep-links to the right Settings pane.
            CommandGroup(replacing: .appSettings) {
                Button("Full Disk Access…") { FullDiskAccess.openSettings() }
                    .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
