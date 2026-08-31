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
        let absolute = URL(fileURLWithPath: directory.path).standardizedFileURL
        var result: [URL] = [URL(fileURLWithPath: "/")]
        var url = result[0]
        for component in absolute.pathComponents where component != "/" {
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
