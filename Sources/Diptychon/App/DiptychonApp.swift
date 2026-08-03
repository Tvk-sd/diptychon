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
        // The whole promise is keyboard-first, but the keymap was only reachable
        // through ⌘, or ⌘K — both of which you have to already know. The menu bar
        // is the one surface a first-time user does look at, and ours was the
        // untouched SwiftUI default (issue 74).
        //
        // Replacing .help rather than adding to it: without CFBundleHelpBookName
        // the stock "Diptychon Help" item opens "Help isn't available", and a menu
        // entry that leads to an error is worse in a first session than none.
        //
        // Deliberately no .keyboardShortcut here — the NSEvent monitor owns the
        // keyboard (Keymap/AppAction), so a SwiftUI shortcut would be a second
        // path that the shortcut editor can't rebind.
        .commands {
            CommandGroup(replacing: .help) {
                SettingsLink { Text("Keyboard Shortcuts…") }
            }
        }

        // Settings window (⌘,) — the shortcut editor (issue 44) plus the Full Disk
        // Access deep-link (issue 10), which used to live on ⌘, in the app menu but
        // now shares this window as a tab.
        Settings {
            SettingsRootView()
        }
    }
}
