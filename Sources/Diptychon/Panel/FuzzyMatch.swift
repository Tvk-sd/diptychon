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

    /// Relevance score for a `candidate` against the pre-normalized `needle`, or
    /// `nil` when the needle isn't an ordered subsequence of it (no match). Higher
    /// is better — used to rank results so the *obvious* hits (`cv-digitalservice`
    /// for "digital") float above scattered ones (`Corpid Light Italic`, whose
    /// d-i-g-i-t-a-l happen to appear spread across the name).
    ///
    /// Walks the **original** candidate (not the normalized form) so word
    /// boundaries survive — the scoring signal lives in *where* a char matches:
    /// - **+10** at a word boundary: start of name, or after a separator
    ///   (`-_. space`), or a camelCase hump (`S` in `DigitalService`).
    /// - **+5** for a contiguous run (this char matched right after the last).
    /// - small penalties for how far in the first match sits, and for long names,
    ///   so tighter/earlier matches win ties.
    ///
    /// **Quality floor:** past 2 chars, a match must either start at a word boundary
    /// or land a contiguous run of at least half the query — otherwise it's a
    /// coincidental scatter (the query's letters merely sprinkled across the name,
    /// e.g. "digital" in "Corpid Light Italic") and returns `nil`. Cuts the noisy
    /// tail without a magnitude threshold to tune.
    static func score(needle: [Character], candidate: String) -> Int? {
        guard !needle.isEmpty else { return nil }
        var ni = 0
        var score = 0
        var firstMatch: Int? = nil
        var firstMatchAtBoundary = false
        var prevMatched = false
        var run = 0
        var longestRun = 0
        var atBoundary = true          // start-of-string is a boundary
        var prevLower = false
        var index = 0
        for ch in candidate {
            let isAlnum = ch.isLetter || ch.isNumber
            let boundary = atBoundary || (ch.isUppercase && prevLower)
            if isAlnum, ni < needle.count, Character(ch.lowercased()) == needle[ni] {
                if firstMatch == nil { firstMatch = index; firstMatchAtBoundary = boundary }
                score += 1
                if boundary { score += 10 }
                if prevMatched { score += 5 }
                run += 1
                longestRun = max(longestRun, run)
                ni += 1
                prevMatched = true
            } else {
                prevMatched = false
                run = 0
            }
            atBoundary = !isAlnum        // next alnum after a separator is a word start
            prevLower = ch.isLowercase
            index += 1
        }
        guard ni == needle.count else { return nil }
        // Quality floor (see doc above). Short queries (≤2) are always noisy, so we
        // don't gate them; longer ones must anchor structurally.
        let minRun = (needle.count + 1) / 2
        guard needle.count <= 2 || firstMatchAtBoundary || longestRun >= minRun else { return nil }
        score -= min(firstMatch ?? 0, 10)   // reward matching near the start
        score -= candidate.count / 20       // gently prefer shorter names
        return score
    }

    /// Does the pre-normalized `needle` appear as an ordered subsequence of
    /// `candidate`? (Inclusion only; use `score` when ranking.) Callers normalize
    /// the query **once** and reuse `needle` across the whole list.
    ///
    /// An empty needle matches nothing: a query that normalizes away (e.g. just
    /// `-`) shows no results rather than dumping the entire tree.
    static func matches(needle: [Character], candidate: String) -> Bool {
        score(needle: needle, candidate: candidate) != nil
    }

    /// Convenience for single calls and tests — normalizes the query for you.
    static func matches(_ query: String, in candidate: String) -> Bool {
        matches(needle: normalize(query), candidate: candidate)
    }
}
