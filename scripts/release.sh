#!/bin/bash
#
# release.sh — build, sign, notarize and staple Diptychon into a shippable zip.
#
# Implements issue 69. Produces build/release/Diptychon.zip, which is what gets
# copied to .scratch/landing-page/dist/ and deployed. Placement and deploy are
# deliberately NOT done here — see "Next steps" printed at the end.
#
# Prerequisites (one-time, interactive — see issue 69):
#   1. A "Developer ID Application" certificate in the login keychain.
#   2. Notary credentials stored under a keychain profile:
#        xcrun notarytool store-credentials diptychon-notary \
#          --key <AuthKey_XXXX.p8> --key-id <KEY_ID> --issuer <ISSUER_UUID>
#
# No keys, passwords or issuer IDs live in this repo — only the profile name.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

NOTARY_PROFILE="${NOTARY_PROFILE:-diptychon-notary}"
DERIVED_DATA=".build-dd"
APP="$DERIVED_DATA/Build/Products/Release/Diptychon.app"
ENTITLEMENTS="Resources/Diptychon.entitlements"
OUT_DIR="build/release"
SUBMIT_ZIP="$OUT_DIR/Diptychon-submit.zip"
FINAL_ZIP="$OUT_DIR/Diptychon.zip"
NOTARY_LOG="$OUT_DIR/notarytool.log"
SUBMISSION_FILE="$OUT_DIR/last-submission-id.txt"
RELEASE_BRANCH="${RELEASE_BRANCH:-main}"

# --resume picks up an in-flight submission whose poller died (network drop).
# It does NOT rebuild — the ticket is bound to the exact binary that was
# submitted, so a fresh build would invalidate it.
RESUME=0
case "${1:-}" in
  --resume) RESUME=1 ;;
  "") ;;
  *) echo "usage: $0 [--resume]" >&2; exit 2 ;;
esac

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31mrelease.sh: %s\033[0m\n' "$1" >&2; exit 1; }

# --- 0. Preflight -------------------------------------------------------------
# Fail here rather than half-way through a five-minute notarization round-trip.

step "Preflight"

IDENTITY_LINES="$(security find-identity -v -p codesigning | grep 'Developer ID Application' || true)"
IDENTITY_COUNT="$(printf '%s' "$IDENTITY_LINES" | grep -c . || true)"

if [ "$IDENTITY_COUNT" -eq 0 ]; then
  fail "no 'Developer ID Application' identity in the keychain.
Create one in Xcode > Settings > Accounts > Manage Certificates > + , then re-run.
(Apple Development / Apple Distribution certificates do NOT work for direct distribution.)"
fi
if [ "$IDENTITY_COUNT" -gt 1 ]; then
  fail "more than one 'Developer ID Application' identity found — refusing to guess:
$IDENTITY_LINES
Set IDENTITY_HASH=<sha1> and re-run, or remove the stale certificate."
fi

# Line shape: `  1) <SHA1> "Developer ID Application: Name (TEAMID)"`
IDENTITY_HASH="${IDENTITY_HASH:-$(printf '%s' "$IDENTITY_LINES" | awk '{print $2}')}"
IDENTITY_NAME="$(printf '%s' "$IDENTITY_LINES" | sed -n 's/.*"\(.*\)".*/\1/p')"
TEAM_ID="$(printf '%s' "$IDENTITY_NAME" | sed -n 's/.*(\([A-Z0-9]*\))$/\1/p')"
[ -n "$TEAM_ID" ] || fail "could not parse the team ID out of: $IDENTITY_NAME"

echo "identity: $IDENTITY_NAME"
echo "team ID:  $TEAM_ID"

if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
  fail "no notary credentials for keychain profile '$NOTARY_PROFILE'.
Run once:
  xcrun notarytool store-credentials $NOTARY_PROFILE \\
    --key <AuthKey_XXXX.p8> --key-id <KEY_ID> --issuer <ISSUER_UUID>
The .p8 downloads exactly once from App Store Connect > Users and Access > Integrations."
fi

[ -f "$ENTITLEMENTS" ] || fail "entitlements missing at $ENTITLEMENTS"

# A release artifact nobody can tie to a commit is worthless — you cannot say
# what is in it. On 2026-08-05 a run built from a foreign branch with a dirty
# tree and produced a notarized bundle that had to be thrown away.
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
# Only build inputs matter. Scratch and docs churn constantly (parallel
# sessions, video harnesses) and cannot change the binary — blocking on them
# would train everyone to reach for RELEASE_ALLOW_DIRTY, which defeats the check.
BUILD_INPUTS="Sources Resources Tests project.yml"
DIRTY="$(git status --porcelain -- $BUILD_INPUTS)"
echo "branch:   $BRANCH ($(git rev-parse --short HEAD))"
[ -z "$(git status --porcelain)" ] || echo "note:     tree has changes outside $BUILD_INPUTS (does not affect the build)"

if [ "${RELEASE_ALLOW_DIRTY:-0}" = "1" ]; then
  echo "warning:  RELEASE_ALLOW_DIRTY=1 — build may not match any commit"
elif [ "$RESUME" = "1" ]; then
  : # resume does not build, so branch and tree state are irrelevant
else
  [ "$BRANCH" = "$RELEASE_BRANCH" ] || fail "on branch '$BRANCH', expected '$RELEASE_BRANCH'.
A release must be traceable to a commit. Switch branches, or set
RELEASE_BRANCH=$BRANCH to release from here on purpose."
  [ -z "$DIRTY" ] || fail "uncommitted build inputs — the binary would match no commit:
$(printf '%s\n' "$DIRTY" | head -10)
Commit or stash first, or set RELEASE_ALLOW_DIRTY=1 to override on purpose."
fi

# --- 1. Build -----------------------------------------------------------------
# Fresh from the current checkout. Issue 69 is explicit: never notarize the old
# zip, it predates the embedded terminal (#65) and everything after it.

if [ "$RESUME" = "1" ]; then
  [ -d "$APP" ] || fail "--resume needs the app bundle from the interrupted run at
$APP
It is gone (a later run's 'rm -rf $DERIVED_DATA' deletes it). The notarization
ticket is bound to that exact binary, so there is nothing to resume — rebuild
and submit again."
  echo "resume:   skipping build and signing, reusing $APP"
else

step "Building Release"
rm -rf "$DERIVED_DATA"
xcodebuild build \
  -scheme Diptychon \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  | tail -5
[ -d "$APP" ] || fail "expected app bundle at $APP but it is not there"

# --- 2. Sign ------------------------------------------------------------------
# Inside-out, no --deep (Apple deprecated it for distribution signing).
# --options runtime  = hardened runtime, required for notarization
# --timestamp        = secure timestamp, required for notarization
# Both are the classic silent rejections.

step "Signing"
# Stray extended attributes (quarantine, Finder info) break codesign.
xattr -cr "$APP"

NESTED_COUNT=0
while IFS= read -r nested; do
  [ -n "$nested" ] || continue
  echo "  nested: ${nested#"$APP/"}"
  codesign --force --options runtime --timestamp --sign "$IDENTITY_HASH" "$nested"
  NESTED_COUNT=$((NESTED_COUNT + 1))
done < <(find "$APP/Contents" \
  \( -name '*.framework' -o -name '*.dylib' -o -name '*.xpc' -o -name '*.appex' \) \
  -depth 2>/dev/null || true)
[ "$NESTED_COUNT" -eq 0 ] && echo "  no nested code (SwiftTerm links statically)"

codesign --force --options runtime --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$IDENTITY_HASH" \
  "$APP"

codesign --verify --strict --verbose=2 "$APP"
codesign -dv --verbose=4 "$APP" 2>&1 | grep -E 'Authority|TeamIdentifier|flags|Timestamp' || true

# --- 3. Notarize --------------------------------------------------------------
# notarytool will not accept a bare .app — it wants a zip/dmg/pkg container.

step "Notarizing (this waits on Apple; usually 1-5 min, first-ever submission took 40)"
mkdir -p "$OUT_DIR"
rm -f "$SUBMIT_ZIP" "$FINAL_ZIP"
ditto -c -k --keepParent "$APP" "$SUBMIT_ZIP"

# notarytool's exit code is not a reliable verdict, so the status is parsed out
# of the output. The submission ID is written to disk before the wait, so a
# dropped connection can be picked up with --resume.
set +e
xcrun notarytool submit "$SUBMIT_ZIP" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait 2>&1 | tee "$NOTARY_LOG"
set -e

SUBMISSION_ID="$(grep -m1 -E '^ +id: ' "$NOTARY_LOG" | awk '{print $2}')"
[ -n "$SUBMISSION_ID" ] && printf '%s\n' "$SUBMISSION_ID" > "$SUBMISSION_FILE"

fi  # end of the non-resume path

if [ "$RESUME" = "1" ]; then
  SUBMISSION_ID="$(cat "$SUBMISSION_FILE" 2>/dev/null || true)"
  [ -n "$SUBMISSION_ID" ] || fail "no submission ID recorded at $SUBMISSION_FILE — nothing to resume."
  step "Resuming submission $SUBMISSION_ID"
  set +e
  xcrun notarytool wait "$SUBMISSION_ID" --keychain-profile "$NOTARY_PROFILE" 2>&1 | tee "$NOTARY_LOG"
  set -e
fi

# --- 3b. Verdict --------------------------------------------------------------
# Accepted is the only status that may proceed to stapling.

STATUS="$(grep -E '^ +status: ' "$NOTARY_LOG" | tail -1 | awk '{print $2}')"
case "$STATUS" in
  Accepted)
    echo "notarization: Accepted (submission $SUBMISSION_ID)"
    ;;
  Invalid|Rejected)
    fail "notarization came back '$STATUS'. Read the reason:
  xcrun notarytool log $SUBMISSION_ID --keychain-profile $NOTARY_PROFILE"
    ;;
  *)
    fail "no usable status in the notary output (got: '${STATUS:-none}').
The submission may still be running at Apple. Check:
  xcrun notarytool info ${SUBMISSION_ID:-<id>} --keychain-profile $NOTARY_PROFILE
If it turns Accepted, pick this run back up without rebuilding:
  $0 --resume"
    ;;
esac

# --- 4. Staple ----------------------------------------------------------------
# The ticket is stapled onto the .app, then the .app is zipped AGAIN. Shipping
# the submission zip would ship an unstapled app: it passes Gatekeeper online
# via ticket lookup and fails offline.

step "Stapling"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"

step "Re-zipping the stapled app"
ditto -c -k --keepParent "$APP" "$FINAL_ZIP"
rm -f "$SUBMIT_ZIP"

# --- 5. Local sanity check ----------------------------------------------------
# NOT the acceptance check. This bundle has no com.apple.quarantine attribute
# (we stripped it in step 2), so Gatekeeper assesses it more leniently than it
# will assess a browser download. Issue 69 accepts only the spctl output from a
# copy downloaded off diptychon.com. Do not paste this output into the ticket.

step "Local sanity check (NOT the acceptance check — see next steps)"
codesign --verify --deep --strict --verbose=2 "$APP"
xcrun stapler validate "$APP"

BYTES="$(stat -f%z "$FINAL_ZIP")"
MB="$(echo "scale=2; $BYTES / 1000000" | bc)"

step "Done"
echo "artifact: $FINAL_ZIP"
echo "size:     $BYTES bytes (~$MB MB)"
cat <<EOF

Next steps (manual, on purpose):
  1. cp "$FINAL_ZIP" .scratch/landing-page/dist/Diptychon.zip
  2. cd .scratch/landing-page && npx wrangler deploy    # bare, no CLI flags
  3. Update every size claim to $MB MB. They disagree with each other today:
     vs.html says 1.5 MB, index.html / dir-a / dir-b / dir-c /
     index-prev-dark say 1.4 MB, and index.html also claims "5 MB installed".
       grep -rn 'MB' .scratch/landing-page/*.html
     The installed size is a separate measurement — du -sh the .app.
  4. THE acceptance check: download from https://diptychon.com/download in a
     browser (a local copy carries no quarantine flag and proves nothing), then
       spctl -a -vv /path/to/downloaded/Diptychon.app
     and paste that output into issue 69. Only then is #69 done and #71 free.
EOF
