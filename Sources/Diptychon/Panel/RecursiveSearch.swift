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
    /// by the chflag-hidden check below, which `.skipsHiddenFiles` misses. Includes
    /// heavy dot-dirs so they stay pruned even when "show hidden" lets the walk into
    /// other dot-folders (e.g. `.scratch`).
    private static let prunedDirNames: Set<String> = [
        "node_modules", ".git", "Pods", ".Trash",
        ".cache", ".npm", ".gradle", "Caches", "DerivedData",
    ]

    /// Path search (Variante B): the query is matched against the whole relative
    /// path, so `bewer digital` finds `Bewerbungen 26/cv-digitalservice.html`. A
    /// hit in the **filename** always outranks one that only lands in a parent
    /// folder — this constant, larger than any realistic path score, lifts every
    /// name match above every path-only match while the fine-grained score still
    /// orders within each tier.
    private static let filenameMatchBonus = 1_000_000

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

        // Collected with their relevance score, sorted at the end so the best
        // matches lead (a prefix hit like `cv-digitalservice` above a name where
        // the query's letters merely appear scattered).
        var results: [(item: FileItem, score: Int)] = []
        var scanned = 0
        for case let url as URL in enumerator {
            if Task.isCancelled { break }
            scanned += 1
            if scanned > scanCap { break }

            // Prune noise subtrees *before* spending budget on them. `~/Library`
            // alone exceeds `scanCap`; without this the walk starves inside it and
            // never reaches the user's documents (the reported "digital" bug).
            let flags = try? url.resourceValues(forKeys: [.isDirectoryKey, .isHiddenKey])
            if flags?.isDirectory == true {
                let name = url.lastPathComponent
                let dotHidden = name.hasPrefix(".")
                // A dir hidden by chflag but *not* dot-prefixed is a system dir like
                // ~/Library (>100k entries) — always skip it, even with hidden shown,
                // or the walk starves. Dot-hidden dirs (.scratch, .config) are only
                // skipped when hidden is off, so "show hidden" makes them searchable.
                let chflagHidden = (flags?.isHidden ?? false) && !dotHidden
                if prunedDirNames.contains(name) || chflagHidden || (!includeHidden && dotHidden) {
                    enumerator.skipDescendants()
                    continue
                }
            }

            // Two-tier path search: a filename hit wins (name score + big bonus);
            // otherwise fall back to matching the whole relative path (query spans
            // folders, or lands only in a parent). Compute the relative path only
            // when the name misses — most entries do, so this stays cheap.
            let score: Int
            if let nameScore = FuzzyMatch.score(needle: needle, candidate: url.lastPathComponent) {
                score = nameScore + filenameMatchBonus
            } else if let pathScore = FuzzyMatch.score(needle: needle,
                                                       candidate: relativePath(of: url, under: rootPath)) {
                score = pathScore
            } else {
                continue
            }

            let values = try? url.resourceValues(forKeys: Set(resourceKeys))
            let isDir = values?.isDirectory ?? false
            // Only pay the per-file xattr read (for colors) when the batched
            // tagNames says this file is actually tagged.
            let tags = (values?.tagNames?.isEmpty == false) ? FinderTag.read(from: url) : []
            results.append((FileItem(
                url: url,
                name: values?.localizedName ?? values?.name ?? url.lastPathComponent,
                size: isDir ? nil : values?.fileSize.map(Int64.init),
                modificationDate: values?.contentModificationDate,
                isDirectory: isDir,
                isHidden: values?.isHidden ?? false,
                tags: tags,
                subtitle: relativeParent(of: url, under: rootPath)
            ), score))
            if results.count >= resultCap { break }
        }
        // Highest score first; stable on ties (keeps the walk's discovery order,
        // which is roughly shallow-before-deep).
        return results.sorted { $0.score > $1.score }.map(\.item)
    }

    /// The entry's full path **relative to the search root** (parent folders +
    /// name), the candidate for path matching. Standardizes the URL to match
    /// `rootPath` (also standardized) — the enumerator yields symlink-resolved
    /// paths, so comparing against the raw `root.path` would miss. Falls back to
    /// the bare name if the URL isn't under the root (shouldn't happen).
    private static func relativePath(of url: URL, under rootPath: String) -> String {
        let full = url.standardizedFileURL.path
        guard full.hasPrefix(rootPath + "/") else { return url.lastPathComponent }
        return String(full.dropFirst(rootPath.count + 1))
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
