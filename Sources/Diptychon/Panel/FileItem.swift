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

    var id: URL { url }

    // Non-optional sort keys: `Optional` isn't `Comparable`, so `Table`'s
    // `KeyPathComparator` needs concrete keypaths. Missing values sort lowest.
    var sizeForSort: Int64 { size ?? -1 }
    var dateForSort: Date { modificationDate ?? .distantPast }
}
