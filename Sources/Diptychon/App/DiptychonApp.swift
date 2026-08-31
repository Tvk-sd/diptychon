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
        // AppKit adds window tabbing for free — "Show Tab Bar", "Merge All Windows"
        // and six more rows across View and Window. Diptychon has no tab concept
        // (issue 38 is untriaged), and stacking windows as tabs fights the two-panel
        // layout the whole product is about. Off means those rows vanish (issue 76).
        NSWindow.allowsAutomaticWindowTabbing = false
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
        // Issue 76: the stock menu bar stated the opposite of what the app does.
        // Undo/Redo/Cut/Copy/Paste/Delete sat permanently greyed because they ask the
        // responder chain and the NSEvent monitor owns the keyboard instead — so the
        // Edit menu denied exactly the reversible-operation story of ADR 0004. And no
        // product command appeared anywhere, while walking the menu bar is the normal
        // way a Mac user meets an app.
        //
        // Every row goes through `ActionMenuItem`, which prints the *current* chord in
        // the title instead of carrying a `.keyboardShortcut` — see the reasoning there.
        .commands {
            CommandGroup(replacing: .undoRedo) {
                ActionMenuItem(action: .undo)
                ActionMenuItem(action: .redo)
            }
            CommandGroup(replacing: .pasteboard) {
                ActionMenuItem(action: .clipboardCopy)
                ActionMenuItem(action: .paste)
                ActionMenuItem(action: .pasteMove)
                ActionMenuItem(action: .copyPaths)
                Divider()
                ActionMenuItem(action: .duplicate)
                ActionMenuItem(action: .trash)
                Divider()
                ActionMenuItem(action: .copyToInactive)
                ActionMenuItem(action: .moveToInactive)
                // SwiftUI's .pasteboard group also carries Select All *with its ⌘A key
                // equivalent*, so replacing the group drops both. That equivalent is
                // load-bearing: the key monitor lets ⌘A through while a text field has
                // focus, and the menu is what selected the text (Go to Folder's path
                // field lives on it — `testGoToFolderNavigates` caught the regression).
                //
                // So this one row keeps a shortcut and routes down the responder chain
                // instead of running an AppAction: with a field focused the field editor
                // answers, with the table focused the monitor has already swallowed ⌘A
                // and run the row-selection action. Both contexts behave as before.
                Divider()
                Button("Select All") {
                    NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("a", modifiers: .command)
                ActionMenuItem(action: .invertSelection)
                ActionMenuItem(action: .selectNone)
            }
            // `after:` rather than `replacing:` — the .newItem group is where the
            // WindowGroup puts New Window, and a file manager has honest use for it.
            CommandGroup(after: .newItem) {
                Divider()
                ActionMenuItem(action: .newFolder)
                ActionMenuItem(action: .newFile)
                ActionMenuItem(action: .rename)
                ActionMenuItem(action: .showTags)
                ActionMenuItem(action: .showInfo)
            }
            CommandMenu("Go") {
                ActionMenuItem(action: .goBack)
                ActionMenuItem(action: .goForward)
                ActionMenuItem(action: .goUp)
                Divider()
                ActionMenuItem(action: .goToFolder)
                ActionMenuItem(action: .focusSearch)
                Divider()
                ActionMenuItem(action: .revealInFinder)
                ActionMenuItem(action: .openWith)
            }
            CommandGroup(after: .sidebar) {
                Divider()
                ActionMenuItem(action: .toggleSidebar)
                ActionMenuItem(action: .toggleTerminal)
                ActionMenuItem(action: .toggleHidden)
                ActionMenuItem(action: .toggleBriefView)
                ActionMenuItem(action: .briefOneColumn)
                ActionMenuItem(action: .briefTwoColumns)
                ActionMenuItem(action: .briefThreeColumns)
                ActionMenuItem(action: .toggleColumnView)
                ActionMenuItem(action: .preview)
            }
            CommandGroup(replacing: .help) {
                // Deliberately absent until diptychon.com/docs existed (issue 74):
                // a menu item that leads nowhere is worse than none. The docs are
                // generated from the same sources DocsKeyboardReferenceTests guards.
                Link("User Guide", destination: URL(string: "https://diptychon.com/docs/")!)
                SettingsLink { Text("Keyboard Shortcuts…") }
                ActionMenuItem(action: .openPalette)
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
