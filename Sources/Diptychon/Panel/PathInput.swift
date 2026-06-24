import Foundation

/// Resolves a user-typed path string into a navigable directory URL (issue 15).
/// Pure + unit-tested so the Go to Folder flow has no surprises: it expands `~`,
/// standardizes the path, and only returns a URL when it exists *and* is a
/// directory — otherwise `nil`, so the caller can show a clear error.
enum PathInput {
    static func resolve(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Expand a leading ~ (or ~/…) to the home directory.
        let expanded = (trimmed as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded).standardizedFileURL

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else { return nil }
        return url
    }
}
