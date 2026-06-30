# 12 — Custom tag color registration (Finder sidebar)

Status: wontfix — resolved via AC3 fallback (decision 2026-06-27); see ADR 0005

## Parent

`.scratch/diptychon-mvp/PRD.md`

## Decision (2026-06-27) — not building this; documented instead

**Resolved: don't register custom-tag colors into Finder's private store.** This is
AC3's explicit fallback ("if direct registration proves too fragile, land a written
rationale + the safest partial approach"). Full rationale: **ADR 0005**.

Read-only probe findings:
- The file xattr layer already works — custom tags (name + color) round-trip with
  Finder *on the file*. That's the part users rely on.
- The custom-tag→color store is undocumented, Finder-owned, version-sensitive, and
  the hypothesized `~/Library/SyncedPreferences/com.apple.finder.plist` **wasn't even
  present** on the dev machine — Finder creates/syncs it lazily.
- Forging it risks desyncing the user's real tags and breaking on macOS updates, for
  a cosmetic gain (custom tag shows in *Finder's* sidebar pre-colored *immediately*
  vs *eventually*, once Finder sees a tagged file).

Decision: do nothing beyond the working xattr; ship the documented rationale. The 7
built-in color tags are unaffected and continue to round-trip (AC2 holds). Revisit
only with a concrete recurring need AND a public/supported registration API — never
by forging the private store. Aligns with transferable-learnings §4 (restraint).

---

_Original scoping below retained for the record; superseded by the decision above._

## What to build

Make a **custom-named** tag created in Diptychon show up in Finder's **sidebar**
with its chosen color — not just as a colored dot on the file.

Split from issue 08 (AC3). Issue 08 writes a tag's name + color correctly to the
file's `com.apple.metadata:_kMDItemUserTags` xattr, so the file's dot is right and
the tag round-trips on the file itself. But Finder's *sidebar* tag list (and the
mapping from a custom tag name → its color) lives in a **separate, undocumented
store** (`com.apple.finder` prefs / `~/Library/SyncedPreferences/com.apple.finder.plist`).
A brand-new custom tag therefore may not appear in Finder's sidebar, or appears
without its color, until Finder itself encounters it.

This issue is to investigate that store and register custom tags + colors so they
appear system-wide in Finder.

## Notes / risks

- The system tag store is **undocumented and version-sensitive**; writing it
  directly is fragile and could break across macOS releases. Probe the current
  format first (read what Finder writes when you create a tag), and prefer the
  least-invasive write. Treat round-trip fidelity with Finder as the bar.
- Consider whether a public/semi-public path exists (e.g. tagging a file then
  letting Finder ingest it) before writing the private store directly.
- Built-in 7 color tags already register correctly via the xattr — don't regress
  them.

## Acceptance criteria

- [ ] A new custom-named tag created in Diptychon (name + color) appears in
      Finder's sidebar with the chosen color.
- [ ] Built-in 7 color tags continue to round-trip (regression check).
- [ ] The store + write approach is documented (an ADR or a doc note), with the
      macOS-version risk called out. If direct registration proves too fragile,
      land a written rationale + the safest partial approach instead.

## Blocked by

- `08-finder-tags`
