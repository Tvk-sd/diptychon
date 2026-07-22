#!/bin/zsh
# v2 choreography (sidebar + copy/paste/undo-toast) with keystroke logging.
# Timing identical to take2.sh.
set -e
zmodload zsh/datetime
cd "$(dirname "$0")"
P=./poke
KEYLOG="${KEYLOG:-keys2.log}"
key() { local label="$1"; shift; print -r -- "$EPOCHREALTIME	$label" >> "$KEYLOG"; $P key "$@"; }
FRONT=$($P front)
[[ "$FRONT" == Diptychon* ]] || { echo "ABORT: frontmost=$FRONT"; exit 1 }
sleep 1.5

# Beat 1 — navigate with sidebar tracking
key "↓" 125; sleep 0.8
key "⏎  Open" 36; sleep 1.0
key "↓" 125; sleep 0.7
key "⏎  Open" 36; sleep 1.0
key "↓" 125; sleep 0.7
key "⏎  Open" 36; sleep 1.0
key "↓" 125; sleep 1.3
key "↓" 125; sleep 1.2

# Beat 2 — select all, copy, paste
key "⌘A  Select all" 0 cmd; sleep 0.9
key "⌘C  Copy" 8 cmd; sleep 0.7
key "⇥  Switch panel" 48; sleep 0.7
key "↓" 125; sleep 0.28; key "↓" 125; sleep 0.28; key "↓" 125; sleep 0.28; key "↓" 125; sleep 0.5
key "⏎  Open" 36; sleep 0.9
key "↓" 125; sleep 0.5
key "⏎  Open" 36; sleep 0.9
key "⌘V  Paste" 9 cmd; sleep 1.6

# Beat 3 — undo → toast, redo → toast
FRONT=$($P front)
[[ "$FRONT" == Diptychon* ]] || { echo "ABORT before undo: frontmost=$FRONT"; exit 1 }
key "⌘Z  Undo" 16 cmd; sleep 2.3
key "⌘⇧Z  Redo" 16 cmd shift; sleep 2.3

# Close the loop
key "⌥←  Back" 123 opt; sleep 0.7
key "⌥←  Back" 123 opt; sleep 0.7
key "⎋  Deselect" 53; sleep 0.35
key "⇥  Switch panel" 48; sleep 0.6
key "⌥←  Back" 123 opt; sleep 0.65
key "⌥←  Back" 123 opt; sleep 0.65
key "⌥←  Back" 123 opt; sleep 0.65
key "⎋  Deselect" 53; sleep 0.3
sleep 2.0
