import Foundation

/// A `PanelSource` (ADR 0003) backed by an explicit, ordered set of `URL`s gathered
/// from many folders — the virtual staging panel (issue 20). The payoff of the
/// `PanelSource` seam: "what a panel lists" was never required to be a directory.
///
/// There is no parent directory to enumerate or watch. Instead each staged URL is
/// validated on load: a file that has since moved or been deleted comes back flagged
/// `isMissing` rather than silently dropped, so the user can see what went stale
/// (greying / exclusion lands in issue 33).
struct StagingSource: PanelSource {
    /// The staged URLs, in the order the user added them.
    let urls: [URL]

    var title: String { "Staging" }

    /// Mirrors `LocalDirectorySource`'s batched keys so a present file builds the
    /// same row a directory listing would (name, size, date, tags).
    private static let resourceKeys: [URLResourceKey] = [
        .nameKey,
        .localizedNameKey,
        .fileSizeKey,
        .contentModificationDateKey,
        .isDirectoryKey,
        .isHiddenKey,
        .tagNamesKey,
    ]

    func load() async throws -> [FileItem] {
        let urls = self.urls
        // Off the main thread (per the protocol contract): per-file `stat`/xattr
        // reads for the whole set should never block the UI.
        return await Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            return urls.map { url in
                // A staged file may have moved or been deleted since it was added.
                guard fm.fileExists(atPath: url.path) else {
                    return FileItem(
                        url: url,
                        name: url.lastPathComponent,
                        size: nil,
                        modificationDate: nil,
                        isDirectory: false,
                        isMissing: true
                    )
                }
                let values = try? url.resourceValues(forKeys: Set(Self.resourceKeys))
                let isDir = values?.isDirectory ?? false
                let tags = (values?.tagNames?.isEmpty == false) ? FinderTag.read(from: url) : []
                return FileItem(
                    url: url,
                    name: values?.localizedName ?? values?.name ?? url.lastPathComponent,
                    size: isDir ? nil : values?.fileSize.map(Int64.init),
                    modificationDate: values?.contentModificationDate,
                    isDirectory: isDir,
                    isHidden: values?.isHidden ?? false,
                    tags: tags
                )
            }
        }.value
    }
}
