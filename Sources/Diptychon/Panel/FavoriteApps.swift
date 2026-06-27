import Foundation

/// Pure helpers for the Open-With menu's favorite apps (issue 28). Mirrors
/// `PinnedFolders`: add/remove/dedup + a path ↔ URL round-trip, kept free of
/// `UserDefaults` so the list logic stays unit-testable in isolation. Matching is
/// by `standardizedFileURL` so the same app added via different path spellings
/// isn't duplicated.
enum FavoriteApps {
    /// Append `app` unless an equivalent app is already favorited (dedup).
    static func adding(_ app: URL, to existing: [URL]) -> [URL] {
        let target = app.standardizedFileURL
        guard !existing.contains(where: { $0.standardizedFileURL == target }) else { return existing }
        return existing + [target]
    }

    /// Drop any favorite equivalent to `app`.
    static func removing(_ app: URL, from existing: [URL]) -> [URL] {
        let target = app.standardizedFileURL
        return existing.filter { $0.standardizedFileURL != target }
    }

    /// Decode persisted paths into app URLs.
    static func decode(_ paths: [String]) -> [URL] {
        paths.map { URL(fileURLWithPath: $0) }
    }

    /// Encode app URLs to paths for `UserDefaults`.
    static func encode(_ urls: [URL]) -> [String] {
        urls.map(\.path)
    }
}
