import Foundation

/// Versioned, `Codable` snapshot of the workspace's restorable state (issue 41).
///
/// This is the durable *shape* of "what survives a restart / remount". It is kept
/// free of `UserDefaults`, `NSWorkspace`, and any live model so the encode/decode
/// round-trip, schema tolerance, sort mapping, and path resolution are all
/// unit-testable in isolation — the same convention `PinnedFolders`/`FavoriteApps`
/// already follow.
///
/// **Governing principle (issue 41 JTBD):** a restore that confuses is worse than no
/// restore. So decode is *tolerant* (unknown/old blobs fall back to defaults rather
/// than crash or wipe), and `RestorePath.resolve` degrades a missing folder to a safe
/// place instead of a broken pane.
///
/// Schema is **additive**: new fields (tabs, columns, view mode — issues 38/27/29/37)
/// arrive as optionals so old blobs keep decoding and newer blobs keep working here.
struct WorkspaceState: Codable, Equatable {
    /// Bump only on a *breaking* shape change. Additive optional fields don't need it.
    static let currentVersion = 1

    var schemaVersion: Int
    var left: PaneState
    var right: PaneState
    /// Left/right pane split fraction (0…1). Optional until wired (issue 41 step 6).
    var splitRatio: Double?
    /// Staged file paths in order. Persisted as path refs; liveness is re-validated on
    /// load by `StagingSource` (issue 33), so missing entries simply grey out.
    var staging: [String]

    init(left: PaneState,
         right: PaneState,
         splitRatio: Double? = nil,
         staging: [String] = [],
         schemaVersion: Int = WorkspaceState.currentVersion) {
        self.schemaVersion = schemaVersion
        self.left = left
        self.right = right
        self.splitRatio = splitRatio
        self.staging = staging
    }
}

/// Per-pane restorable state. Filters are deliberately absent (issue 41): panes
/// always reopen unfiltered, so a stale filter can never hide files on launch.
struct PaneState: Codable, Equatable {
    var directoryPath: String
    var sort: PaneSort
}

/// A persistable sort descriptor. The live `Table` uses `KeyPathComparator<FileItem>`,
/// which isn't `Codable`; this maps the four real columns to a stable string + a
/// direction and back.
struct PaneSort: Codable, Equatable {
    enum Column: String, Codable { case name, kind, date, size }
    var column: Column
    var ascending: Bool

    /// Newest-first — the app's default sort (`PanelModel.sortOrder`, issue 29).
    static let `default` = PaneSort(column: .date, ascending: false)
}

// MARK: - Sort ↔ KeyPathComparator mapping

extension PaneSort {
    /// Derive a persistable descriptor from the live comparator. Unknown key paths
    /// (should never happen for the four columns) fall back to the default.
    init(_ comparators: [KeyPathComparator<FileItem>]) {
        guard let first = comparators.first, let column = Column(first.keyPath) else {
            self = .default
            return
        }
        self.column = column
        self.ascending = first.order == .forward
    }

    /// Rebuild the live comparator the `Table` header drives.
    var comparators: [KeyPathComparator<FileItem>] {
        let order: SortOrder = ascending ? .forward : .reverse
        switch column {
        case .name: return [KeyPathComparator(\FileItem.name, order: order)]
        case .kind: return [KeyPathComparator(\FileItem.kind, order: order)]
        case .date: return [KeyPathComparator(\FileItem.dateForSort, order: order)]
        case .size: return [KeyPathComparator(\FileItem.sizeForSort, order: order)]
        }
    }
}

private extension PaneSort.Column {
    /// Match a comparator's erased key path to one of the four sortable columns.
    init?(_ keyPath: PartialKeyPath<FileItem>) {
        if keyPath == \FileItem.name { self = .name }
        else if keyPath == \FileItem.kind { self = .kind }
        else if keyPath == \FileItem.dateForSort { self = .date }
        else if keyPath == \FileItem.sizeForSort { self = .size }
        else { return nil }
    }
}

// MARK: - Persistence store

/// Reads/writes the single versioned snapshot under one `UserDefaults` key —
/// consistent with the existing per-property convention, but as one atomic blob.
enum WorkspaceStateStore {
    static let key = "workspaceState"

    static func encode(_ state: WorkspaceState) -> Data? {
        try? JSONEncoder().encode(state)
    }

    /// Tolerant decode: malformed data, a missing required field, or a *newer* schema
    /// than this build understands all return `nil` (→ caller uses defaults). Extra
    /// keys from a future additive field are ignored by `JSONDecoder`, so a forward
    /// blob at the same version still decodes.
    static func decode(_ data: Data) -> WorkspaceState? {
        guard let state = try? JSONDecoder().decode(WorkspaceState.self, from: data),
              state.schemaVersion <= WorkspaceState.currentVersion
        else { return nil }
        return state
    }

    /// Load from `UserDefaults`, or `nil` if nothing valid is stored.
    static func load(_ defaults: UserDefaults = .standard) -> WorkspaceState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return decode(data)
    }

    /// Persist, or clear the key if encoding somehow fails (never leave a half blob).
    static func save(_ state: WorkspaceState, to defaults: UserDefaults = .standard) {
        if let data = encode(state) {
            defaults.set(data, forKey: key)
        }
    }
}

// MARK: - Restore path resolution

/// Decides where a restored directory should actually open, given what exists on disk
/// right now. Pure and injectable (no `FileManager`/`NSWorkspace` calls) so the
/// unmounted-vs-gone rule — the trust-critical part of issue 41 — is unit-testable.
enum RestorePath {
    enum Resolution: Equatable {
        /// The folder exists and is reachable — open it as saved.
        case use(URL)
        /// The folder is on a currently-unmounted volume — open `fallback` now, but
        /// remember `target` and restore it if that volume comes back (issue 41 remount).
        case pending(target: URL, fallback: URL)
        /// The folder is permanently gone — open the nearest existing ancestor / home.
        case fallback(URL)
    }

    /// - Parameters:
    ///   - path: the saved directory path.
    ///   - home: last-resort fallback (typically `URL.startDirectory`).
    ///   - fileExists: predicate for "this directory exists & is reachable".
    ///   - mountedVolumeRoots: absolute roots currently mounted (e.g. `/Volumes/Data`).
    ///     Used to tell "drive temporarily unmounted" from "folder permanently gone".
    static func resolve(path: String,
                        home: URL,
                        fileExists: (String) -> Bool,
                        mountedVolumeRoots: [String]) -> Resolution {
        let target = URL(fileURLWithPath: path, isDirectory: true)
        if fileExists(path) { return .use(target) }

        // On an external volume that isn't mounted right now? Remember and wait.
        if let root = volumeRoot(of: path), !mountedVolumeRoots.contains(root) {
            let fallback = nearestExisting(of: path, fileExists: fileExists) ?? home
            return .pending(target: target, fallback: fallback)
        }

        // Otherwise the folder is genuinely gone — degrade to nearest ancestor / home.
        return .fallback(nearestExisting(of: path, fileExists: fileExists) ?? home)
    }

    /// `/Volumes/NAME/...` → `/Volumes/NAME`; `nil` for paths not on a mounted volume.
    static func volumeRoot(of path: String) -> String? {
        let prefix = "/Volumes/"
        guard path.hasPrefix(prefix) else { return nil }
        let name = path.dropFirst(prefix.count).prefix { $0 != "/" }
        guard !name.isEmpty else { return nil }
        return prefix + name
    }

    /// Walk up ancestors until one exists. `nil` if even the root doesn't (never, but
    /// keeps the caller honest).
    static func nearestExisting(of path: String, fileExists: (String) -> Bool) -> URL? {
        var url = URL(fileURLWithPath: path, isDirectory: true).deletingLastPathComponent()
        while url.path != "/" {
            if fileExists(url.path) { return url }
            url = url.deletingLastPathComponent()
        }
        return fileExists("/") ? URL(fileURLWithPath: "/", isDirectory: true) : nil
    }
}
