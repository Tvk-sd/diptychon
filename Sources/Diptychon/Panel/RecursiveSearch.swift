import Foundation

/// Bounded, cancellable recursive name search under a root directory (issue 21
/// slice 3). Walks the subtree off the main thread, matching file/folder names
/// (case-insensitive substring), and **stops at `resultCap` matches** so searching
/// a huge tree (e.g. Home) can't peg CPU / balloon RAM — the exact runaway shape
/// `context/transferable-learnings.md` §10 warns about. Cancellation is honoured on
/// every step, so a new keystroke abandons the in-flight walk immediately.
enum RecursiveSearch {
    /// Hard ceiling on matches returned. Past this we stop walking — a query like
    /// "e" under Home would otherwise enumerate the whole tree.
    static let resultCap = 1000
    /// Ceiling on *entries scanned*, regardless of matches. Bounds the **work** (not
    /// just the output) so a sparse query under a huge tree stays responsive instead
    /// of grinding for minutes — the effort half of transferable-learnings §10.
    /// Results may be partial past this; acceptable for an MVP find.
    static let scanCap = 100_000

    /// Resource keys prefetched per entry so building a row needs no extra syscall
    /// (mirrors `LocalDirectorySource`).
    private static let resourceKeys: [URLResourceKey] = [
        .nameKey, .localizedNameKey, .fileSizeKey,
        .contentModificationDateKey, .isDirectoryKey, .tagNamesKey,
    ]

    /// Run the search. `nonisolated`/`async` (no actor isolation), so awaiting it
    /// from the `@MainActor` model runs the blocking enumeration on a background
    /// cooperative thread while still observing the calling task's cancellation.
    static func run(query: String, in root: URL, includeHidden: Bool) async -> [FileItem] {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return [] }

        let fm = FileManager.default
        let rootPath = root.standardizedFileURL.path
        // No prefetch keys: the walk is a cheap name-only `readdir`, and we fetch
        // resource values lazily for matches alone (below). Prefetching for every
        // entry — especially the tag xattr — is what made searching Home crawl.
        // Skip package descendants so we don't dive into every .app bundle.
        var options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants]
        if !includeHidden { options.insert(.skipsHiddenFiles) }
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: options
        ) else { return [] }

        var results: [FileItem] = []
        var scanned = 0
        for case let url as URL in enumerator {
            if Task.isCancelled { return results }
            scanned += 1
            if scanned > scanCap { break }
            guard url.lastPathComponent.lowercased().contains(needle) else { continue }

            let values = try? url.resourceValues(forKeys: Set(resourceKeys))
            let isDir = values?.isDirectory ?? false
            // Only pay the per-file xattr read (for colors) when the batched
            // tagNames says this file is actually tagged.
            let tags = (values?.tagNames?.isEmpty == false) ? FinderTag.read(from: url) : []
            results.append(FileItem(
                url: url,
                name: values?.localizedName ?? values?.name ?? url.lastPathComponent,
                size: isDir ? nil : values?.fileSize.map(Int64.init),
                modificationDate: values?.contentModificationDate,
                isDirectory: isDir,
                tags: tags,
                subtitle: relativeParent(of: url, under: rootPath)
            ))
            if results.count >= resultCap { break }
        }
        return results
    }

    /// The match's containing folder relative to the search root, for the result's
    /// location subtitle. `nil` for a direct child of the root (nothing to show).
    private static func relativeParent(of url: URL, under rootPath: String) -> String? {
        let parent = url.deletingLastPathComponent().standardizedFileURL.path
        guard parent != rootPath else { return nil }
        if parent.hasPrefix(rootPath + "/") {
            return String(parent.dropFirst(rootPath.count + 1))
        }
        return parent   // fallback: not under root (shouldn't happen) → full path
    }
}
