import Foundation

/// Resolves a user-typed path string into a navigable directory URL (issue 15).
/// Pure + unit-tested so the Go to Folder flow has no surprises: it expands `~`,
/// standardizes the path, and only returns a URL when it exists *and* is a
/// directory — otherwise `nil`, so the caller can show a clear error.
enum PathInput {
    /// Resolve `raw` to an existing directory URL. Absolute paths (and `~/…`) are
    /// taken as-is; a **relative** path resolves against `base` (the active panel's
    /// folder) so typing `Music` while in `/Users/Till` lands on `/Users/Till/Music`.
    static func resolve(_ raw: String, relativeTo base: URL? = nil) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Expand a leading ~ (or ~/…) to the home directory.
        let expanded = (trimmed as NSString).expandingTildeInPath
        let url: URL
        if expanded.hasPrefix("/") {
            url = URL(fileURLWithPath: expanded).standardizedFileURL
        } else if let base {
            url = base.appendingPathComponent(expanded).standardizedFileURL
        } else {
            url = URL(fileURLWithPath: expanded).standardizedFileURL
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else { return nil }
        return url
    }
}
