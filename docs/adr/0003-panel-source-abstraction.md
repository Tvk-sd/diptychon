# Panel Source abstraction; MVP lists local folders only

A Panel renders a **Panel Source**, modeled as an abstraction from day 1. In the
MVP the only implementation is a local directory, but the rest of the app talks
to the abstraction, not to the filesystem directly.

## Considered Options

- **Hard-code panels to local directories** — simplest, but every future view
  (tags, search, archives) would require reworking panel internals.
- **Abstract the panel source from the start, ship only the local-directory
  implementation** — chosen.

## Consequences

- Future sources — tag view (all files with tag X), search results, archive
  contents — become new implementations of the same interface, not a rewrite.
- Explicit MVP exclusions: **browsing archives as folders, network volumes
  (SMB/FTP), and virtual/tag/search views are out of scope** until the local
  core is solid. Archives in particular are the most expensive item and are
  deliberately deferred despite the reference app (Nimble Commander) having them.
- Tag view is the expected first post-MVP source, since Finder tags are already
  a must-have.
