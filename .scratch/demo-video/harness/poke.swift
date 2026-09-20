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
    // <appName> matches by owner name; a numeric argument matches by owner pid,
    // which is the only safe form while a real instance of the app is running.
    let name = args[2]
    let wantPid = Int(name)
    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
    // The largest window is the document window; a palette or sheet is smaller
    // and would otherwise win just by being first in the list.
    var best: (id: Int, b: [String: CGFloat], area: CGFloat)? = nil
    for w in list {
        if let want = wantPid {
            guard let owner = w[kCGWindowOwnerPID as String] as? Int, owner == want else { continue }
        }
        guard let owner = w[kCGWindowOwnerName as String] as? String, wantPid != nil || owner == name,
              let layer = w[kCGWindowLayer as String] as? Int, layer == 0,
              let b = w[kCGWindowBounds as String] as? [String: CGFloat],
              let id = w[kCGWindowNumber as String] as? Int else { continue }
        let area = b["Width"]! * b["Height"]!
        if best == nil || area > best!.area { best = (id, b, area) }
    }
    guard let w = best else { exit(1) }
    print("\(w.id) \(Int(w.b["X"]!)) \(Int(w.b["Y"]!)) \(Int(w.b["Width"]!)) \(Int(w.b["Height"]!))")
    exit(0)
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
case "drag":
    // press at (x1,y1), move to (x2,y2), release - used to resize a window by
    // its edge when the app ignores an AX resize
    let p1 = CGPoint(x: Double(args[2])!, y: Double(args[3])!)
    let p2 = CGPoint(x: Double(args[4])!, y: Double(args[5])!)
    CGWarpMouseCursorPosition(p1); usleep(120_000)
    CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: p1, mouseButton: .left)!.post(tap: .cghidEventTap)
    usleep(150_000)
    let steps = 24
    for i in 1...steps {
        let t = Double(i) / Double(steps)
        let p = CGPoint(x: p1.x + (p2.x - p1.x) * t, y: p1.y + (p2.y - p1.y) * t)
        CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: p, mouseButton: .left)!.post(tap: .cghidEventTap)
        usleep(12_000)
    }
    usleep(120_000)
    CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: p2, mouseButton: .left)!.post(tap: .cghidEventTap)
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
