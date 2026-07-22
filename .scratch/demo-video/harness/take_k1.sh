#!/bin/zsh
# v1 choreography with keystroke logging: every event appends "epoch<TAB>label"
# to $KEYLOG for the badge-overlay pass. Timing identical to take.sh (take 6).
set -e
zmodload zsh/datetime
cd "$(dirname "$0")"
P=./poke
KEYLOG="${KEYLOG:-keys1.log}"
key() { local label="$1"; shift; print -r -- "$EPOCHREALTIME	$label" >> "$KEYLOG"; $P key "$@"; }
mark() { print -r -- "$EPOCHREALTIME	$1" >> "$KEYLOG"; }
FRONT=$($P front)
[[ "$FRONT" == Diptychon* ]] || { echo "ABORT: frontmost=$FRONT"; exit 1 }
sleep 1.5

# Beat 1 — dual-pane navigation
key "↓" 125; sleep 0.8
key "⏎  Open" 36; sleep 1.0
key "↓" 125; sleep 0.7
key "⏎  Open" 36; sleep 1.0
key "↓" 125; sleep 0.7
key "⏎  Open" 36; sleep 1.0
key "↓" 125; sleep 1.4
key "↓" 125; sleep 1.1
key "↓" 125; sleep 1.1

key "⇥  Switch panel" 48; sleep 0.7
key "↓" 125; sleep 0.28; key "↓" 125; sleep 0.28; key "↓" 125; sleep 0.28; key "↓" 125; sleep 0.5
key "⏎  Open" 36; sleep 0.9
key "↓" 125; sleep 0.3; key "↓" 125; sleep 0.5
key "⏎  Open" 36; sleep 0.9
key "↓" 125; sleep 0.3; key "↓" 125; sleep 0.3; key "↓" 125; sleep 0.6
sleep 0.9

# Beat 2 — search + path jump
key "⌘F  Search" 3 cmd; sleep 0.6
mark "typing “harbor”"
$P type "harbor" 140
sleep 1.8
key "⌘A  Select all" 0 cmd; sleep 0.35
printf '%s' '/Users/Till/Studio/Dev/portfolio-site/src' | pbcopy
key "⌘V  Paste path" 9 cmd; sleep 1.3
key "⌘K  Command palette" 40 cmd; sleep 0.9
key "⎋  Close" 53; sleep 0.5
key "↓" 125; sleep 1.5

# Beat 3 — history
key "⌥←  Back" 123 opt; sleep 0.85
key "⌥←  Back" 123 opt; sleep 0.85
key "⌥←  Back" 123 opt; sleep 0.85
key "⌥→  Forward" 124 opt; sleep 0.85
key "⌥←  Back" 123 opt; sleep 0.85
key "⎋  Deselect" 53; sleep 0.4
key "⇥  Switch panel" 48; sleep 0.6
key "⌥←  Back" 123 opt; sleep 0.7
key "⌥←  Back" 123 opt; sleep 0.7
key "⌥←  Back" 123 opt; sleep 0.7
key "⎋  Deselect" 53; sleep 0.3
sleep 2.0
