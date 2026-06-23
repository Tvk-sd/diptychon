import AppKit

/// Full Disk Access detection + the Settings deep-link (issue 10). macOS has no
/// public "am I granted FDA?" API, so we **probe** an FDA-gated location: listing
/// `~/Library/Safari` succeeds only with Full Disk Access. FDA can't be requested
/// programmatically (ADR 0001) — we can only detect its absence and guide the user.
enum FullDiskAccess {
    /// True if we appear to have Full Disk Access (heuristic — see type doc).
    static var isGranted: Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        // Primary probe: a folder readable only with FDA.
        let safari = home.appendingPathComponent("Library/Safari", isDirectory: true)
        if FileManager.default.fileExists(atPath: safari.path) {
            return (try? FileManager.default.contentsOfDirectory(atPath: safari.path)) != nil
        }
        // Fallback (Safari folder absent): the user TCC store is FDA-gated too.
        let tcc = home.appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")
        return FileManager.default.isReadableFile(atPath: tcc.path)
    }

    /// Open System Settings → Privacy & Security → Full Disk Access.
    static func openSettings() {
        guard let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
        else { return }
        NSWorkspace.shared.open(url)
    }
}
