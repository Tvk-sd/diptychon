import Foundation

/// The MVP's only `PanelSource` (ADR 0003): the contents of one local directory.
struct LocalDirectorySource: PanelSource {
    let directory: URL
    /// Whether to include hidden (dot) files. Driven by the Panel's toggle.
    var includeHidden: Bool = false

    var title: String { directory.path }

    /// Resource keys we prefetch in a single batched call so that building rows
    /// needs no per-file `stat()` syscall. This is what keeps a ~50k-file folder
    /// scrolling smoothly (PRD §2): the cost is paid once, up front.
    private static let resourceKeys: [URLResourceKey] = [
        .nameKey,
        .localizedNameKey, // Finder-style display name (e.g. "Musik" for Music).
        .fileSizeKey,
        .contentModificationDateKey,
        .isDirectoryKey,
        .tagNamesKey, // cheap, batched; signals which files need the xattr color read.
    ]

    func load() async throws -> [FileItem] {
        let directory = self.directory
        let options: FileManager.DirectoryEnumerationOptions = includeHidden ? [] : [.skipsHiddenFiles]
        // `Task.detached` guarantees the enumeration runs off the main thread —
        // marking a function `async` alone does not (ADR-adjacent; PRD §2).
        return try await Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            let urls = try fm.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: Self.resourceKeys,
                options: options
            )

            return urls.map { url in
                let values = try? url.resourceValues(forKeys: Set(Self.resourceKeys))
                let isDir = values?.isDirectory ?? false
                // Only pay the per-file xattr read (for colors) when the batched
                // tagNames says this file is actually tagged.
                let tags = (values?.tagNames?.isEmpty == false) ? FinderTag.read(from: url) : []
                return FileItem(
                    url: url,
                    name: values?.localizedName ?? values?.name ?? url.lastPathComponent,
                    size: isDir ? nil : values?.fileSize.map(Int64.init),
                    modificationDate: values?.contentModificationDate,
                    isDirectory: isDir,
                    tags: tags
                )
            }
        }.value
    }
}
