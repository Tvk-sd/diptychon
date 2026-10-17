# 101 — Re-key signing and ship 0.2.0

Status: **CLOSED (2026-10-17)** — 0.2.0 is live on diptychon.com, signed, notarized and stapled. One confirmation left with Till (real browser download), noted below.
Category: release

## Parent

`.scratch/diptychon-mvp/PRD.md` · runbook: `context/notarization-runbook.md` · predecessor: **#69** (closed, proved the pipeline works)

## Problem

Version 0.2.0 (build 2) has been committed since 2026-09-21 (`772cbaa`) and has
never shipped. `diptychon.com/download` still serves the 0.1.x artefact that
was notarized on 2026-08-11.

The release pipeline itself is fine — #69 proved it end to end. What is gone are
both credentials it needs. Verified on 2026-10-11:

| Check | Result |
|---|---|
| `security find-identity -v -p codesigning` | `0 valid identities found` |
| `~/Library/Application Support/notarytool` | does not exist |
| `~/.appstoreconnect/private_keys` | does not exist |
| `mdfind -name AuthKey_` | no hit (not proof — Spotlight does not index everything) |

| `ls ~/Library/Keychains/` | no `login_renamed_*.keychain-db` — the old keychain was not set aside, so the old certificate and its private key are unrecoverable |

The keychain folder dates from 2026-09-03/04, so this looks like a machine or
keychain reset. The runbook still records the old state as current (certificate
present, team `XDCAAWJ75G`, `notAfter=Feb 1 2027`, profile `diptychon-notary` in
the keychain). That table is now stale and gets corrected as part of this issue.

A second thing rides along. The notary key ID stood in `PLAN.md` and in
`context/notarization-runbook.md` in a public repo for months. The text is
redacted (`a29f9c8`), but git history keeps it. Revoking the key is the only
real fix, and since a new key has to be stored anyway, the revoke costs nothing
extra here.

## Decision

Do the re-key and the 0.2.0 release as one trip, in this order: revoke first,
then issue, then store, then release. Do not restore the old key in order to
revoke it.

## Plan

**Finding 2026-10-11: Xcode cannot make a usable certificate on this machine.**

Xcode 26.6 on macOS 26.5.1 created three Developer ID Application certificates
(04.08.26, and two on 11.10.26) and reported no error. None of them produced a
private key on this Mac. Proven on the real call path, not by inference:

| Check | Result |
|---|---|
| `security find-identity -v` (any policy) | `0 valid identities found` |
| `security find-certificate -a -c "Developer ID"` across login + System | 0 |
| `codesign -s "Developer ID Application"` on a throwaway binary | `no identity found` |
| private keys in the login keychain named for the team | none |

These are cloud-managed certificates: Apple holds the private half, and only
Xcode's own archive and export flow can use them. `scripts/release.sh` calls
`codesign` directly, so they are useless to it. Keychain Access is gone from
macOS 26, so the old Certificate Assistant route is gone with it. The
certificate therefore has to be requested from the developer portal against a
locally generated key.

**Agent — done 2026-10-11, ahead of Till**

- Apple's **Developer ID Certification Authority (G2)** intermediate was missing
  from the keychain entirely. Downloaded from `apple.com/certificateauthority`
  and imported. Without it a correct leaf certificate still shows up as invalid,
  which would have read as a second failure.
- Generated an RSA 2048 key and a CSR in `/tmp/diptychon-cert.cMynLK` (folder 700, key 600,
  deliberately outside the repo — the repo is public). The CSR is copied to
  `~/Desktop/DiptychonSigning.certSigningRequest` for the upload.

**Till — one visit to the developer portal (~5 minutes)**

1. App Store Connect ▸ Users and Access ▸ Integrations ▸ App Store Connect API
   ▸ Team Keys: revoke the old key, create a new one with role **Developer**.
   The `.p8` downloads exactly once — put it straight into the password manager,
   together with the Key ID and the Issuer ID.
2. **Stop clicking `+` in Xcode.** Every click burns one certificate against the
   team cap and yields nothing usable. Instead: `developer.apple.com/account` ▸
   Certificates, Identifiers and Profiles ▸ Certificates ▸ `+` ▸ **Developer ID
   Application** ▸ profile type **G2 Sub-CA**. Upload
   `~/Desktop/DiptychonSigning.certSigningRequest`, download the `.cer`, report
   where it landed.
   - If **Developer ID Application is greyed out**, stop and report. Creating one
     needs the Account Holder role; Xcode shows the role as "Admin", which fits
     with Xcode only ever offering cloud-managed certificates. The fallback is
     cloud signing via `xcodebuild -exportArchive`, which means rewriting
     `release.sh` — a separate decision, not a quick fix.
   - If the portal reports the **certificate cap is reached**, the two from
     **11.10.26** are safe to revoke: they never signed anything. The one from
     **04.08.26** must not be touched — it signed the live 0.1.x download, and
     revoking it would break that download and every installed copy immediately.
     Revoking is not the same as expiring; a secure timestamp protects against
     expiry only.
3. Store the notary credentials, **on one line**:

   ```bash
   xcrun notarytool store-credentials diptychon-notary --key <path-to-new-AuthKey.p8> --key-id <KEY_ID> --issuer <ISSUER_UUID>
   ```

   A line break after `store-credentials` makes zsh read the rest as its own
   command. That failed twice on 2026-08-05.
4. Delete the `.p8` from disk once it is in the password manager. Keeping a copy
   is fine in `~/.appstoreconnect/private_keys/` (`chmod 700` folder, `chmod 600`
   file).
5. Be at the Mac for the first `release.sh` run. A freshly imported key triggers a
   keychain access prompt on the first real signature; without a click on
   **Always Allow** the script hangs.

**Certificate — DONE 2026-10-11, verified on the real call path**

The portal route worked. Till had simply scrolled past the "Software" group on
`/account/resources/certificates/add`; role and membership were never the problem.
The CSR was signed against G2 Sub-CA and the leaf imported cleanly.

| Check | Result |
|---|---|
| Subject | `Developer ID Application: Till von Krueger (XDCAAWJ75G)` — same team as before |
| Issuer | `Developer ID Certification Authority / G2` |
| Validity | `Oct 11 2026` to `Sep 17 2031` — five years, not the six months the cloud-managed certificate gave in August |
| Modulus match | leaf and local key hash identical |
| `security find-identity -v -p codesigning` | 1 valid identity |
| `codesign --options runtime --timestamp` on a throwaway binary | signed; chain resolves leaf to Developer ID CA to Apple Root CA, timestamp present, `--verify --strict` passes |

The first signature blocked on a keychain access prompt until Till clicked
**Always Allow**, exactly as expected for a freshly imported key. It will not
ask again.

Plaintext key material is deleted. The identity is archived as
`~/Desktop/Diptychon-signing-identity.p12`. **Till: put that file and its password
into the password manager, then delete it from the Desktop.** August's lesson was
that a keychain reset destroys the private half beyond recovery; an archived
`.p12` makes the next reset a two-minute import instead of this afternoon.

**Agent — the release run, once both credentials verify**

6. Preflight: `security find-identity -v -p codesigning` shows the identity,
   `xcrun notarytool history --keychain-profile diptychon-notary` answers.
7. `./scripts/release.sh` from a clean `main`, without a pipe (a pipe buffers
   and reports `tail`'s exit code — the 2026-08-05 trap). Expect 2–10 minutes.
8. Copy `build/release/Diptychon.zip` to `.scratch/landing-page/dist/`, then
   `npx wrangler deploy` bare from `.scratch/landing-page` — CLI-flag deploys
   drop the www domain.
9. Re-measure zip bytes and installed size and update the figures on the page.
   The local 0.2.0 build is 9.9 MB installed against 9.0 MB for 0.1.x, so the
   current "2.7 MB / 9 MB" on the site is wrong either way. Scope lives in #78.
10. Acceptance: download through a real browser from `https://diptychon.com/download`,
    then `spctl -a -vv` on the downloaded copy. Expect `accepted` and
    `source=Notarized Developer ID`. Paste the output here. A local test proves
    nothing — only a browser download carries `com.apple.quarantine`.

Step 10 normally overwrites `/Applications/Diptychon.app`. Ask Till first.

## Assumptions

- The Apple Developer membership is still active. It was bought 2026-08-04 as a
  yearly subscription (ADR 0008), so it should run to ~2027-08. Not verified
  against the Apple account from here. If it has lapsed, step 2 fails and this
  issue turns into a renewal first.
- The team ID stays `XDCAAWJ75G`. `scripts/release.sh` reads it from
  `security find-identity`, so nothing is hardcoded and a different team would
  still work.
- `main` is clean and in sync with `origin/main`, and `772cbaa` is an ancestor
  of `HEAD` — both checked on 2026-10-11. `release.sh` refuses a dirty tree or a
  non-`main` branch unless overridden.

## Side finding

`/Applications/Diptychon.app` is **not** the notarized download. It is an ad-hoc
signed local build of 0.1.0 (build 1), installed 2026-09-20. That voids the
open "Doppelklick-Gegenprobe" item in `PLAN.md`: double-clicking that app says
nothing about Gatekeeper, because a locally copied app carries no quarantine
attribute. The check it describes is the same check as step 10 above, so it
should be folded into this issue and dropped from `PLAN.md`.

## Outcome

**Shipped 2026-10-17.** Both credentials were re-issued and 0.2.0 replaced the
August 0.1.x artefact on diptychon.com. Committed as `2f335bf`.

| Step | Result |
|---|---|
| Certificate | new Developer ID Application, team `XDCAAWJ75G`, valid to 2031-09-17 |
| Notary key | old key `8274…` revoked by Till on 2026-10-11, new key stored as profile `diptychon-notary` |
| Notarization | submission `e23ba90b-8c2f-4829-a3cb-85eabc2b42bd`, `status: Accepted`, stapled, re-zipped |
| Artefact | `build/release/Diptychon.zip`, 3.062.803 bytes (~3,06 MB), installed 9,9 MB |
| Deploy | worker version `35e36103-d8de-4c01-a40d-6a86c5d60c5b`, both custom domains |
| Site copy | 110 occurrences of "2.7 MB" to "3.1 MB", 2 of "9 MB installed" to "10 MB", across 13 live pages plus `llms.txt`, `llms-full.txt`, `docs/` — competitor figures untouched |

Verified against the live site, not the working copy: the zip served by
`diptychon.com/download` matches the notarized artefact byte for byte
(sha256 `d015de03…9636f15`), and on that downloaded copy, with the quarantine
attribute applied, Gatekeeper answers:

```
accepted
source=Notarized Developer ID
origin=Developer ID Application: Till von Krueger (XDCAAWJ75G)
```

**Still with Till, five minutes.** The quarantine flag above was written by hand,
not by a browser, so one real download still closes this.

1. **Quit the running Diptychon first.** `/Applications/Diptychon.app` is an ad-hoc
   local build of 0.1.0, same bundle id. Double-clicking the download would only
   re-activate the running instance, which proves nothing and reads as a pass.
2. Download from `https://diptychon.com/download` in a browser, then open the app.
3. **Read the dialog carefully.** A notarized app still shows one on first open:
   *"...downloaded from the Internet. Apple checked it for malicious software..."*
   with an **Open** button. **That dialog is the pass.** A failure says *"Apple
   could not verify..."* and offers only Move to Trash or Done.
4. Then drag 0.2.0 into `/Applications`, replacing the ad-hoc 0.1.0 — this is the
   original ask, "get the updated version running". The signature changes from
   ad-hoc to Developer ID, so macOS may ask again for folder or Full Disk Access.
   Expected, not a bug.

This also retires the old "Doppelklick-Gegenprobe" item, which was void anyway:
it pointed at the ad-hoc build, and a locally copied app carries no quarantine
attribute at all.

### What this cost, and what prevents the repeat

The September keychain reset destroyed the signing key beyond recovery, and
Xcode 26 could not replace it: its `+` button only issues cloud-managed
certificates whose private half stays with Apple, invisible to `codesign`. The
route that worked was a CSR generated with `openssl` (Keychain Access no longer
exists on macOS 26) against the developer portal. The identity is archived: Till stored it in
Bitwarden on 2026-10-17, base64-encoded as text, because the password manager
does not take file attachments — the same trick that saved the notary key this
session. A third keychain reset is now an import, not an afternoon. The export
`~/Desktop/Diptychon-signing-identity.p12` still exists on the Desktop and should
be deleted.
