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
        .isHiddenKey, // batched; lets the list dim hidden rows when they're shown.
        .contentTypeKey, // batched UTType → the Kind column (issue 29).
    ]

    /// `resourceKeys` plus the tag names. Tags are xattr-backed, and reading
    /// xattrs on a TCC-protected folder *node* (~/Desktop et al.) is what makes
    /// macOS throw three permission dialogs at first launch (issue 77) — plain
    /// stat-based keys above never prompt. So tags are fetched per row and only
    /// for rows outside `tccProtectedFolders`.
    private static let resourceKeysWithTags: [URLResourceKey] =
        resourceKeys + [.tagNamesKey]

    /// The user folders macOS gates behind a per-app TCC consent dialog.
    /// Listing their *parent* is free; touching their xattrs is not. The price
    /// of skipping tags here: no tag dots on exactly these rows.
    private static let tccProtectedFolders: Set<URL> = {
        let fm = FileManager.default
        return Set(
            [FileManager.SearchPathDirectory.desktopDirectory, .documentDirectory, .downloadsDirectory]
                .compactMap { try? fm.url(for: $0, in: .userDomainMask, appropriateFor: nil, create: false) }
                .map { $0.standardizedFileURL }
        )
    }()

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
                let isProtected = Self.tccProtectedFolders.contains(url.standardizedFileURL)
                let keys = isProtected ? Self.resourceKeys : Self.resourceKeysWithTags
                let values = try? url.resourceValues(forKeys: Set(keys))
                let isDir = values?.isDirectory ?? false
                // Only pay the per-file xattr read (for colors) when the batched
                // tagNames says this file is actually tagged. Protected folders
                // (issue 77) never get here: their tagNames is never fetched.
                let tags = (values?.tagNames?.isEmpty == false) ? FinderTag.read(from: url) : []
                return FileItem(
                    url: url,
                    name: values?.localizedName ?? values?.name ?? url.lastPathComponent,
                    size: isDir ? nil : values?.fileSize.map(Int64.init),
                    modificationDate: values?.contentModificationDate,
                    isDirectory: isDir,
                    isHidden: values?.isHidden ?? false,
                    tags: tags,
                    kind: FileItem.kind(for: url, isDirectory: isDir, contentType: values?.contentType)
                )
            }
        }.value
    }
}
