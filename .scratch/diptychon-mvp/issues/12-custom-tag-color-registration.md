# 12 — Custom tag color registration (Finder sidebar)

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/PRD.md`

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
