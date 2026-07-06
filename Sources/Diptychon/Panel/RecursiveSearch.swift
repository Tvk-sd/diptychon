import Foundation

/// Bounded, cancellable recursive name search under a root directory (issue 21
/// slice 3). Walks the subtree off the main thread, matching file/folder names
/// (fuzzy — normalized subsequence, see `FuzzyMatch`), and **stops at `resultCap`
/// matches** so searching
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
        .contentModificationDateKey, .isDirectoryKey, .isHiddenKey, .tagNamesKey,
    ]

    /// Directory names we never recurse into — dev/system noise that would burn the
    /// scan budget without holding anything the user searches for. `~/Library` is
    /// *not* here: it carries the `hidden` chflag (not a dot-prefix), so it's pruned
    /// by the hidden-directory check below, which `.skipsHiddenFiles` misses.
    private static let prunedDirNames: Set<String> = [
        "node_modules", ".git", "Pods", ".Trash",
    ]

    /// Run the search. `nonisolated`/`async` (no actor isolation), so awaiting it
    /// from the `@MainActor` model runs the blocking enumeration on a background
    /// cooperative thread while still observing the calling task's cancellation.
    static func run(query: String, in root: URL, includeHidden: Bool) async -> [FileItem] {
        // Normalize the query once (lowercase, letters/digits only); reused for
        // every candidate below. Empty after normalizing (e.g. a lone "-") ⇒
        // nothing to match, so bail rather than walk the whole tree.
        let needle = FuzzyMatch.normalize(query)
        guard !needle.isEmpty else { return [] }

        let fm = FileManager.default
        let rootPath = root.standardizedFileURL.path
        // Prefetch only the two cheap `stat` flags the walk itself needs to decide
        // whether to recurse (isDirectory) and whether to prune (isHidden). Batched
        // by the enumerator, so no extra syscall per entry. The expensive keys
        // (tags/size/dates) are still fetched lazily for matches alone, below —
        // prefetching the tag xattr for every entry is what made Home crawl.
        // Skip package descendants so we don't dive into every .app bundle.
        var options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants]
        if !includeHidden { options.insert(.skipsHiddenFiles) }
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
            options: options
        ) else { return [] }

        var results: [FileItem] = []
        var scanned = 0
        for case let url as URL in enumerator {
            if Task.isCancelled { return results }
            scanned += 1
            if scanned > scanCap { break }

            // Prune noise subtrees *before* spending budget on them. `~/Library`
            // alone exceeds `scanCap`; without this the walk starves inside it and
            // never reaches the user's documents (the reported "digital" bug).
            let flags = try? url.resourceValues(forKeys: [.isDirectoryKey, .isHiddenKey])
            if flags?.isDirectory == true {
                let hiddenDir = !includeHidden && (flags?.isHidden ?? false)
                if hiddenDir || prunedDirNames.contains(url.lastPathComponent) {
                    enumerator.skipDescendants()
                    continue
                }
            }

            guard FuzzyMatch.matches(needle: needle, candidate: url.lastPathComponent) else { continue }

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
                isHidden: values?.isHidden ?? false,
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
