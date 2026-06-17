import Foundation

/// The MVP's only `PanelSource` (ADR 0003): the contents of one local directory.
struct LocalDirectorySource: PanelSource {
    let directory: URL

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
    ]

    func load() async throws -> [FileItem] {
        let directory = self.directory
        // `Task.detached` guarantees the enumeration runs off the main thread —
        // marking a function `async` alone does not (ADR-adjacent; PRD §2).
        return try await Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            let urls = try fm.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: Self.resourceKeys,
                options: [.skipsHiddenFiles] // hidden-file toggle is a later issue.
            )

            return urls.map { url in
                let values = try? url.resourceValues(forKeys: Set(Self.resourceKeys))
                let isDir = values?.isDirectory ?? false
                return FileItem(
                    url: url,
                    name: values?.localizedName ?? values?.name ?? url.lastPathComponent,
                    size: isDir ? nil : values?.fileSize.map(Int64.init),
                    modificationDate: values?.contentModificationDate,
                    isDirectory: isDir
                )
            }
        }.value
    }
}
