import Foundation

/// Pure helpers for the sidebar's pinned-folder list (issue 16, slice 2). Kept
/// free of `UserDefaults` so add/remove/dedup and the path ↔ URL round-trip are
/// unit-testable in isolation. Matching is by `standardizedFileURL` so the same
/// folder pinned via different path spellings isn't duplicated.
enum PinnedFolders {
    /// Append `url` unless an equivalent folder is already pinned (dedup).
    static func adding(_ url: URL, to existing: [URL]) -> [URL] {
        let target = url.standardizedFileURL
        guard !existing.contains(where: { $0.standardizedFileURL == target }) else { return existing }
        return existing + [target]
    }

    /// Drop any pin equivalent to `url`.
    static func removing(_ url: URL, from existing: [URL]) -> [URL] {
        let target = url.standardizedFileURL
        return existing.filter { $0.standardizedFileURL != target }
    }

    /// Decode persisted paths into directory URLs.
    static func decode(_ paths: [String]) -> [URL] {
        paths.map { URL(fileURLWithPath: $0, isDirectory: true) }
    }

    /// Encode URLs to paths for `UserDefaults`.
    static func encode(_ urls: [URL]) -> [String] {
        urls.map(\.path)
    }
}
