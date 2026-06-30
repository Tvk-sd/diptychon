# Custom tag colors are not registered into Finder's private store

Diptychon writes Finder tags (name + color) to a file's
`com.apple.metadata:_kMDItemUserTags` xattr, which round-trips correctly with
Finder on the file itself (ADR 0004 / issue 08). A separate question — issue 12 —
is whether a **custom-named** tag created in Diptychon should also appear in
Finder's **sidebar tag list** already colored, system-wide, before Finder has
encountered a file carrying that tag.

We decided **not** to do this.

## Considered Options

- **Forge Finder's custom-tag→color store directly** — write the undocumented,
  Finder-owned store (historically `~/Library/SyncedPreferences/com.apple.finder.plist`
  and/or `com.apple.finder` prefs) so a custom tag shows in the sidebar pre-colored.
  Rejected.
- **Register only the name** into `com.apple.finder` `FavoriteTagNames` (the sidebar
  list), accepting the color resolves only once Finder sees a tagged file. Still
  mutates Finder prefs; marginal value. Rejected.
- **Do nothing beyond the file xattr; document the decision** — chosen.

## Why

- The custom-tag→color store is **undocumented and version-sensitive**. On the dev
  machine (2026-06-27) the hypothesized `SyncedPreferences` plist **did not even
  exist** — Finder creates/syncs it lazily. Writing it is fragile and can silently
  break on a macOS update.
- It is **Finder-owned**: `cfprefsd` caches it and Finder may overwrite our writes,
  so correctness can't be guaranteed without fighting the system.
- **Low value for the risk.** The part users actually rely on already works: the
  colored dot on the file, the tag round-tripping with Finder on the file, and the
  built-in 7 colors everywhere. Finder also surfaces a custom tag in its own UI once
  it encounters a tagged file. The only delta this feature buys is "appears in
  *Finder's* sidebar immediately and pre-colored" vs "eventually" — a cosmetic gain
  in a *different app*.
- It works against the product's differentiator (**lightweight + reliable**):
  hand-writing another app's private database is exactly the kind of fragile,
  surprising behavior the app is positioned against.

This is the fallback AC3 of issue 12 explicitly allows ("if direct registration
proves too fragile, land a written rationale + the safest partial approach").

## Consequences

- Custom tags created in Diptychon are correct **on files** and round-trip with
  Finder; they are **not** pre-registered into Finder's sidebar with color. Finder
  surfaces them through its normal tag-discovery once it sees a tagged file.
- The **7 built-in color tags are unaffected** and continue to round-trip.
- No dependency on an undocumented store; nothing to break across macOS releases.
- Revisit only if a concrete, recurring need appears AND a public/supported API for
  tag registration exists — not by forging the private store.
