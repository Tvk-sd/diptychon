import AppKit

// SwiftPM executable entry point. Bootstraps a normal AppKit app and hands off
// to `AppDelegate`, which builds the window. See DiptychonApp.swift for why we
// drive AppKit explicitly instead of using the SwiftUI `App` lifecycle.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
