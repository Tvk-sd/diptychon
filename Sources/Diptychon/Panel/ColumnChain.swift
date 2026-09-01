import Foundation

/// The column browser's chain of folders (issue 91).
///
/// **Derived, not stored.** The chain is a pure function of the pane's current
/// `directory`: every ancestor, then the directory itself. The last column is
/// therefore always the folder the pane is in — which is the list the pane already
/// shows — so breadcrumb, copy destination, terminal cwd and ⌘←/⌘→ all keep reading
/// the one `directory` with no special case for this view.
///
/// The alternative, keeping the chain as its own state, puts `directory` in a cycle
/// with the first column and forces patches at every call site that asks "where is
/// this pane?".
///
/// Selection reads through the same derivation: the item highlighted in column *i* is
/// whichever child of that folder leads to column *i+1*. Nothing has to remember it.
enum ColumnChain {
    /// Root → `directory`, one entry per column.
    ///
    /// Built from the absolute, standardized path's components — **not** by looping
    /// `deletingLastPathComponent()`, which never converges for the directory-style
    /// URLs `contentsOfDirectory` returns and once pinned the CPU (issue 21). Same
    /// construction as the breadcrumb's `trail(of:)`, deliberately: one walker, so the
    /// two can't disagree about where you are.
    ///
    /// Not capped. The breadcrumb trims to its last few because it has one line to
    /// live in; the browser scrolls horizontally instead and keeps the last column in
    /// view, so trimming here would hide ancestors the user can otherwise scroll back
    /// to.
    static func columns(for directory: URL) -> [URL] {
        columns(from: URL(fileURLWithPath: "/"), to: directory)
    }

    /// `root` → `directory`, one entry per column.
    ///
    /// **The first column is where you navigated to, not the filesystem root**
    /// (Till, 2026-09-01: „wenn ich projects navigiere ist project der header folder
    /// nicht till oder noch welche drüber, die logik entsteht aus der navigation in
    /// der linken leiste"). Clicking *Projects* in the sidebar makes Projects the
    /// first column; the columns then grow to the right as you walk in. That is how
    /// the Finder behaves, and it keeps the view about the subtree you chose rather
    /// than about the whole disk.
    ///
    /// Built from path components — **not** by looping `deletingLastPathComponent()`,
    /// which never converges for the directory-style URLs `contentsOfDirectory` hands
    /// back and once pinned the CPU (issue 21).
    ///
    /// If `directory` is not inside `root` the anchor is stale (the pane was moved
    /// somewhere else entirely), and the chain collapses to `directory` alone. The
    /// caller re-anchors on the next navigation; showing an unrelated ancestor chain
    /// in the meantime would be worse than showing one column.
    static func columns(from root: URL, to directory: URL) -> [URL] {
        let rootPath = URL(fileURLWithPath: root.path).standardizedFileURL
        let target = URL(fileURLWithPath: directory.path).standardizedFileURL
        let rootParts = rootPath.pathComponents
        let targetParts = target.pathComponents
        guard targetParts.count >= rootParts.count,
              Array(targetParts.prefix(rootParts.count)) == rootParts else {
            return [target]
        }
        var result: [URL] = [rootPath]
        var url = rootPath
        for component in targetParts.dropFirst(rootParts.count) {
            url.appendPathComponent(component)
            result.append(url)
        }
        return result
    }

    /// Which entry of column `index` is highlighted, given the whole chain: the folder
    /// that leads to the next column. The last column has no successor, so its
    /// selection is the user's own and this returns nil.
    static func selectedChild(inColumnAt index: Int, chain: [URL]) -> URL? {
        guard index >= 0, index + 1 < chain.count else { return nil }
        return chain[index + 1]
    }
}
