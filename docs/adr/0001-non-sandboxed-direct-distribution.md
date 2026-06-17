# Non-sandboxed app, direct distribution, no App Store

The app is a Norton-Commander-style dual-panel file manager that must roam the
entire filesystem freely. We ship it **non-sandboxed with Full Disk Access** and
distribute it **directly** (GitHub Releases + Homebrew Cask), **not via the App
Store**. These choices are coupled: the App Store mandates the sandbox, and the
sandbox would force per-folder security-scoped bookmarks — exactly the friction
that kills the "fast & lightweight" promise for a file manager.

## Considered Options

- **App Store / sandboxed** — rejected: sandbox forbids free filesystem roaming
  without per-folder bookmark management; fights the core use case.
- **Non-sandboxed, direct distribution** — chosen.

## Consequences

- Free roaming of the whole filesystem; no security-scoped bookmark layer to
  build — simpler codebase.
- Security responsibility shifts to us; larger attack surface.
- User must grant Full Disk Access manually (System Settings → Privacy); cannot
  be requested programmatically — needs good first-run onboarding.
- Code signing / notarization is deferred (optional); until then Gatekeeper
  shows friction acceptable for a technical OSS audience.
- App Store is foreclosed unless a separate sandboxed variant is built later —
  retrofitting the sandbox would mean rearchitecting all file access. Reversing
  this decision is expensive, which is why it is fixed now.
