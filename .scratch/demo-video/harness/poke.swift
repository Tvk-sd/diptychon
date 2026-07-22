// Demo-driver: post synthetic events / query windows for the Diptychon demo video.
// Modes:
//   poke winfo <appName>            → "windowId x y w h" of frontmost window of app
//   poke activate <pid>             → bring app to front
//   poke key <keycode> [cmd|shift|opt|ctrl ...]
//   poke type <string> <delayMs>    → per-char unicode typing
//   poke click <x> <y>              → left click at global point
//   poke move <x> <y>               → warp cursor
import Cocoa

let args = CommandLine.arguments
func flags(from tokens: ArraySlice<String>) -> CGEventFlags {
    var f = CGEventFlags()
    for t in tokens {
        switch t {
        case "cmd": f.insert(.maskCommand)
        case "shift": f.insert(.maskShift)
        case "opt": f.insert(.maskAlternate)
        case "ctrl": f.insert(.maskControl)
        default: break
        }
    }
    return f
}

switch args[1] {
case "winfo":
    let name = args[2]
    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
    for w in list {
        guard let owner = w[kCGWindowOwnerName as String] as? String, owner == name,
              let layer = w[kCGWindowLayer as String] as? Int, layer == 0,
              let b = w[kCGWindowBounds as String] as? [String: CGFloat],
              let id = w[kCGWindowNumber as String] as? Int else { continue }
        print("\(id) \(Int(b["X"]!)) \(Int(b["Y"]!)) \(Int(b["Width"]!)) \(Int(b["Height"]!))")
        exit(0)
    }
    exit(1)
case "front":
    let f = NSWorkspace.shared.frontmostApplication
    print(f?.localizedName ?? "none", f?.processIdentifier ?? -1)
case "activate":
    guard let app = NSRunningApplication(processIdentifier: pid_t(Int32(args[2])!)) else { exit(1) }
    app.activate(options: [.activateIgnoringOtherApps])
    usleep(300_000)
case "key":
    let code = CGKeyCode(UInt16(args[2])!)
    var f = flags(from: args[3...])
    if [123, 124, 125, 126].contains(code) {   // arrows: mimic hardware flags
        f.insert(.maskSecondaryFn); f.insert(.maskNumericPad)
    }
    let down = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true)!
    let up = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false)!
    down.flags = f; up.flags = f
    down.post(tap: .cghidEventTap); usleep(60_000); up.post(tap: .cghidEventTap)
case "type":
    let delay = UInt32(args[3])! * 1000
    for ch in args[2] {
        let units = Array(String(ch).utf16)
        let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!
        down.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
        let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)!
        up.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
        down.post(tap: .cghidEventTap); usleep(30_000); up.post(tap: .cghidEventTap)
        usleep(delay)
    }
case "click":
    let p = CGPoint(x: Double(args[2])!, y: Double(args[3])!)
    CGWarpMouseCursorPosition(p); usleep(150_000)
    let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: p, mouseButton: .left)!
    let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: p, mouseButton: .left)!
    down.post(tap: .cghidEventTap); usleep(80_000); up.post(tap: .cghidEventTap)
case "move":
    CGWarpMouseCursorPosition(CGPoint(x: Double(args[2])!, y: Double(args[3])!))
case "frame":
    let app = AXUIElementCreateApplication(pid_t(Int32(args[2])!))
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
          let win = (value as? [AXUIElement])?.first else { exit(1) }
    var pos = CGPoint(x: Double(args[3])!, y: Double(args[4])!)
    var size = CGSize(width: Double(args[5])!, height: Double(args[6])!)
    AXUIElementSetAttributeValue(win, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &pos)!)
    AXUIElementSetAttributeValue(win, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &size)!)
default:
    FileHandle.standardError.write("unknown mode\n".data(using: .utf8)!)
    exit(2)
}
