import Foundation

/// Lightweight fuzzy name matching (issue: search finds `digitalservice` for
/// `digital-`). Shared by both text-match paths — the recursive Search
/// (`RecursiveSearch`) and the current-folder Filter (`PanelModel.applyFilters`)
/// — so they behave identically no matter which field the user reaches for.
///
/// **Deliberately not AI.** No embeddings, no index, no ML — the segment has no
/// AI demand (netnography T-E) and the toolkit-as-lens trap is documented in
/// `transferable-learnings.md` §20. This is the classic command-palette trick
/// (VSCode / fzf): normalize, then subsequence-match.
///
/// Two rules, both cheap and pure:
/// 1. **Normalize** — lowercase and keep letters/digits only. So a stray
///    separator in the query (`digital-`, `my_file`) can't break a match, and
///    `foo-bar` matches `foobar`.
/// 2. **Subsequence** — the query's characters must appear *in order* in the
///    candidate, but not contiguously. So `digital` and `digserv` both hit
///    `digitalservice`; `digital` alone did already, but `digital-` and
///    acronyms are what strict substring couldn't reach.
///
/// Not covered (Slice 2, only if wanted): typo tolerance (`dgital` → `digital`),
/// which needs bounded edit distance, and relevance ranking. Subsequence is
/// looser than substring, so medium queries surface more (and noisier) hits —
/// acceptable for an MVP find; revisit with a score floor if it feels noisy.
enum FuzzyMatch {
    /// Lowercase and strip everything but letters/digits. Umlauts survive
    /// (`ä` is a letter), so German filenames match as typed.
    static func normalize(_ s: String) -> [Character] {
        s.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    /// Does the pre-normalized `needle` appear as an ordered subsequence of
    /// `candidate`? Callers normalize the query **once** and reuse `needle`
    /// across the whole walk/list — the candidate is normalized inline here so
    /// no throwaway String is built per entry beyond the lowercasing the old
    /// substring path already paid.
    ///
    /// An empty needle matches nothing: a query that normalizes away (e.g. just
    /// `-`) shows no results rather than dumping the entire tree.
    static func matches(needle: [Character], candidate: String) -> Bool {
        guard !needle.isEmpty else { return false }
        var i = 0
        for ch in candidate.lowercased() where ch.isLetter || ch.isNumber {
            if ch == needle[i] {
                i += 1
                if i == needle.count { return true }
            }
        }
        return false
    }

    /// Convenience for single calls and tests — normalizes the query for you.
    static func matches(_ query: String, in candidate: String) -> Bool {
        matches(needle: normalize(query), candidate: candidate)
    }
}
