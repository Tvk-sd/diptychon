#!/bin/zsh
# v3 — tight ~24s hero cut. Right pane to destination first, then: navigate,
# ⌘A, ⌘⌥→ copy-to-other-panel (10 imgs), back up with ⌘⇧S staging on the way,
# ⌘⇧B staging flash, ⌘K palette → run Undo → toast finale.
# Keycodes: down=125 ret=36 tab=48 esc=53 a=0 z(DE)=16 k=40 s=1 b=11
# right=124 up=126.
set -e
zmodload zsh/datetime
cd "$(dirname "$0")"
P=./poke
KEYLOG="${KEYLOG:-keys3.log}"
key() { local label="$1"; shift; print -r -- "$EPOCHREALTIME	$label" >> "$KEYLOG"; $P key "$@"; }
mark() { print -r -- "$EPOCHREALTIME	$1" >> "$KEYLOG"; }
FRONT=$($P front)
[[ "$FRONT" == Diptychon* ]] || { echo "ABORT: frontmost=$FRONT"; exit 1 }
sleep 1.2

# Destination first: right pane → Clients/Nordwind Records
key "⇥  Switch panel" 48; sleep 0.45
key "↓" 125; sleep 0.15; key "↓" 125; sleep 0.15; key "↓" 125; sleep 0.15; key "↓" 125; sleep 0.35
key "⏎  Open" 36; sleep 0.6
key "↓" 125; sleep 0.3
key "⏎  Open" 36; sleep 0.6
key "⇥  Switch panel" 48; sleep 0.45

# Navigate to the shoot
key "↓" 125; sleep 0.4
key "⏎  Open" 36; sleep 0.75
key "↓" 125; sleep 0.4
key "⏎  Open" 36; sleep 0.75
key "↓" 125; sleep 0.4
key "⏎  Open" 36; sleep 0.8

# Select all 10 → send to other panel
key "⌘A  Select all" 0 cmd; sleep 0.7
key "⌘⌥→  Copy to other panel" 124 cmd opt; sleep 1.6

# Back up the path
key "⎋" 53; sleep 0.4
key "⌘↑  Up" 126 cmd; sleep 0.8
key "⌘↑  Up" 126 cmd; sleep 1.0

# Palette finale: run Undo → toast
FRONT=$($P front)
[[ "$FRONT" == Diptychon* ]] || { echo "ABORT before palette: frontmost=$FRONT"; exit 1 }
key "⌘K  Command palette" 40 cmd; sleep 1.1
key "⏎  Run “Undo”" 36; sleep 2.4
sleep 1.2
