# Distribution

How to get Diptychon onto someone else's Mac. This is the operational runbook
that implements [ADR 0001 — non-sandboxed, direct distribution](adr/0001-non-sandboxed-direct-distribution.md).
The ADR is the *decision*; this doc is the *how*, and it evolves as our setup does.

## Where we are vs. where we're going

| | Current (no Apple Developer account) | Target (once we have Developer ID) |
|---|---|---|
| **Signing** | Ad-hoc (`codesign --sign -`) | Developer ID + **notarized** by Apple |
| **Format** | `.zip` of the `.app` | Notarized, stapled `.dmg` |
| **Channel** | Hand-sent zip to trusted testers | **GitHub Releases + Homebrew Cask** |
| **Tester friction** | One-time Gatekeeper bypass (below) | Double-click, no bypass |
| **Cost** | Free | $99/yr Apple Developer Program |

We are honest about this: today's path asks each tester to do one manual step,
because notarization is deferred (see ADR 0001). Don't imply the polished path
works yet — it doesn't until we buy Developer ID.

---

## Current path — send to a few testers (free)

### 1. Build a Release `.app`

```sh
xcodebuild build -scheme Diptychon -configuration Release \
  -derivedDataPath .build-dd
# → .build-dd/Build/Products/Release/Diptychon.app
```

### 2. Ad-hoc sign

Stops the *"app is damaged"* error. Harmless — this is the same
"Sign to Run Locally" identity Xcode uses.

```sh
codesign --force --deep --sign - \
  .build-dd/Build/Products/Release/Diptychon.app
```

### 3. Zip it

`.zip`, not `.dmg` — an unsigned `.dmg` adds a *second* quarantine layer to
explain. Zip is the lowest-friction free format.

```sh
ditto -c -k --keepParent \
  .build-dd/Build/Products/Release/Diptychon.app Diptychon.zip
```

Send `Diptychon.zip`.

---

## Instructions to paste to your testers

> **Opening Diptychon the first time**
>
> Diptychon isn't yet notarized by Apple, so macOS blocks it on first launch.
> This is expected. To open it:
>
> 1. Unzip `Diptychon.zip` and move **Diptychon.app** to `/Applications`.
> 2. **Right-click** the app → **Open** → **Open** in the dialog.
> 3. If macOS still refuses (Sequoia and later are stricter):
>    **System Settings → Privacy & Security →** scroll down → **"Open Anyway"**.
>
> Still stuck? Run this once in Terminal, then reopen:
>
> ```sh
> xattr -dr com.apple.quarantine /Applications/Diptychon.app
> ```
>
> **Full Disk Access:** some file operations need it. Diptychon guides you
> through granting it (System Settings → Privacy & Security → Full Disk Access)
> on first use.

### Why these steps

- **"Damaged" vs. "unidentified developer" are different errors.** Ad-hoc
  signing (step 2 above) fixes *"damaged"*; the quarantine bypass fixes
  *"unidentified developer."* A build can trip both.
- The `com.apple.quarantine` attribute is what triggers Gatekeeper; stripping it
  (or right-click → Open, which sets an exception) lets an unsigned app run.

---

## Target path — notarized (in progress)

We joined the Apple Developer Program on 2026-08-04. Signing and notarization
now have a working script and their own runbook:

> **[`context/notarization-runbook.md`](../context/notarization-runbook.md)** —
> the standing document for signing, notarizing and shipping. `scripts/release.sh`
> is the executable form of it.

**Since 2026-08-10 this is the live path:** the zip served at
diptychon.com/download is signed, notarized and stapled; a real browser
download passes `spctl -a -vv` with `source=Notarized Developer ID` (issue 69,
closed). Testers no longer need the bypass above — it stays documented only as
a fallback for unsigned local dev builds.

Outline of what remains after that:

1. **Sign** with a Developer ID Application certificate.
2. **Notarize** — `xcrun notarytool submit … --wait`, then
   `xcrun stapler staple` the ticket onto the `.app` / `.dmg`.
3. **Package** as a `.dmg`.
4. **Publish** to GitHub Releases; point a **Homebrew Cask** at the release
   asset so `brew install --cask diptychon` works.

At that point a tester just double-clicks — no bypass, no Terminal.

---

## See also

- [ADR 0001 — non-sandboxed, direct distribution](adr/0001-non-sandboxed-direct-distribution.md) — the decision and its rationale.
- [README → Install & run](../README.md#install--run) — building from source.
