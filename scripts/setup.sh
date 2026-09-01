#!/bin/sh
# One-command project setup. Run after cloning, after editing project.yml,
# or after adding/removing any .swift file. Idempotent — safe to re-run anytime.
set -eu

cd "$(dirname "$0")/.."

if [ "$(uname)" != "Darwin" ]; then
  echo "setup.sh must run on macOS (needs Homebrew + XcodeGen + Xcode)." >&2
  exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found — install it first: https://brew.sh" >&2
    exit 1
  fi
  echo "==> Installing XcodeGen (one-time)…"
  brew install xcodegen
fi

echo "==> Generating Diptychon.xcodeproj from project.yml…"
xcodegen generate

cat <<'EOF'

Done. Next steps:

  open Diptychon.xcodeproj      # build & run in Xcode (⌘R)

or from the command line:

  xcodebuild -scheme Diptychon -destination 'platform=macOS' build
  xcodebuild -scheme Diptychon -destination 'platform=macOS' test

Reminders:
  - The .xcodeproj is generated and gitignored — re-run ./scripts/setup.sh
    whenever you edit project.yml or add/remove a .swift file.
  - Signing is ad-hoc ("Sign to Run Locally") — no Developer team needed.
  - Some file operations need Full Disk Access; the app guides you on first use.
  - Optional: DIPTYCHON_DIR=/some/path overrides the start folder.
EOF
