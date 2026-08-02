import Foundation

/// Resolves the user's terminal app for "Open in Terminal" (issue 57) — the
/// external-launch variant: the folder URL is handed to the terminal app, which
/// Terminal.app and iTerm both read as "new window, cwd = this folder". No
/// AppleScript, so no automation-consent prompt.
///
/// The app is configurable as a plain `UserDefaults` string (`terminalAppName`,
/// e.g. "iTerm"), the same no-settings-UI pattern as the hotkey overrides
/// (issue 44). An unresolvable name falls back to Terminal.app — visibly, at
/// the call site, never silently.
enum TerminalLauncher {
    static let defaultsKey = "terminalAppName"
    static let fallbackName = "Terminal"

    /// The configured app name, defaulting to Terminal. Missing or
    /// whitespace-only values mean "default", so a stray `defaults write`
    /// can't brick ⌘⇧T.
    static func configuredName(from defaults: UserDefaults = .standard) -> String {
        let name = defaults.string(forKey: defaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? fallbackName : name
    }

    /// Where an app named `name` may live, in search order. Pure, so the order
    /// is unit-testable. A value containing "/" or ending in ".app" is an
    /// explicit bundle path (tilde expanded); a bare name is tried in the
    /// standard app folders — Terminal.app itself lives in
    /// /System/Applications/Utilities.
    static func candidatePaths(for name: String) -> [String] {
        if name.contains("/") || name.hasSuffix(".app") {
            return [(name as NSString).expandingTildeInPath]
        }
        return [
            "/Applications/\(name).app",
            "/System/Applications/Utilities/\(name).app",
            "/System/Applications/\(name).app",
            ("~/Applications/\(name).app" as NSString).expandingTildeInPath,
        ]
    }

    /// Resolve `name` to an app bundle URL, or nil if no candidate exists on
    /// disk. `exists` is injectable for tests; the default asks the filesystem.
    static func resolve(_ name: String,
                        exists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }) -> URL? {
        candidatePaths(for: name).first(where: exists).map { URL(fileURLWithPath: $0) }
    }
}
