import Foundation

/// One row in a Panel: a single entry from whatever the Panel's `PanelSource`
/// lists. In the MVP that is always a file or folder on disk, but the type is
/// deliberately source-agnostic so tag/search/archive sources (ADR 0003) can
/// produce the same rows later.
struct FileItem: Identifiable, Hashable {
    /// The on-disk location. Doubles as a stable identity for `Table` so it can
    /// track rows across reloads without re-diffing by name.
    let url: URL
    let name: String
    /// Logical file size in bytes. `nil` for folders (we don't size folders).
    let size: Int64?
    let modificationDate: Date?
    let isDirectory: Bool
    /// Whether the OS considers this a hidden file (dot-prefixed or the hidden
    /// flag). Only ever `true` when the panel's "show hidden" toggle is on; the
    /// list dims these rows so they read as secondary (issue: gray hidden files).
    var isHidden: Bool = false
    /// Apple Finder tags read from the file's xattr (issue 08). Part of equality
    /// so a tag change marks the row as changed on reload.
    var tags: [FinderTag] = []
    /// Containing folder shown under search (issue 21 slice 3): the match's parent
    /// path **relative to the search root**. `nil` outside search and for direct
    /// children of the root (no location to disambiguate).
    var subtitle: String? = nil
    /// The staged file no longer exists on disk (issue 20). Set by `StagingSource`
    /// on load when the URL is gone; later slices grey such rows and exclude them
    /// from operations (issue 33). Always `false` for directory-backed rows.
    var isMissing: Bool = false

    var id: URL { url }

    // Non-optional sort keys: `Optional` isn't `Comparable`, so `Table`'s
    // `KeyPathComparator` needs concrete keypaths. Missing values sort lowest.
    var sizeForSort: Int64 { size ?? -1 }
    var dateForSort: Date { modificationDate ?? .distantPast }
}
