#!/bin/zsh
# Path-jump cut for the Substack post "Legibility beats speed".
# The point of the clip: pasting an ABSOLUTE FILE path jumps the pane into the
# file's folder AND leaves the weak grey landing marker on the file itself.
# (The old #62 demo pasted a *folder* path — isDir → highlightedTargetURL = nil,
# so no marker was ever on screen. That footage cannot carry this post.)
# Keycodes: f=3 v=9 esc=53 k=40
set -e
zmodload zsh/datetime
cd "$(dirname "$0")"
P=./poke
KEYLOG="${KEYLOG:-keys_jump.log}"
key() { local label="$1"; shift; print -r -- "$EPOCHREALTIME	$label" >> "$KEYLOG"; $P key "$@"; }

# Till's own Diptychon may be running. Assert the frontmost app is the *staged*
# pid, not just "some Diptychon" — otherwise ⌘V would paste the path into his
# live search field and navigate his pane.
FRONT=$($P front)
[[ "$FRONT" == "Diptychon ${STAGED_PID:?STAGED_PID not set}" ]] \
  || { echo "ABORT: frontmost='$FRONT', expected 'Diptychon $STAGED_PID'"; exit 1 }

sleep 1.6                      # hold on the origin folder — "where I was"

key "⌘F  Search" 3 cmd;   sleep 1.1
key "⌘V  Paste path" 9 cmd; sleep 3.2   # live navigate + landing marker
key "⎋  Dismiss search" 53; sleep 3.0   # marker persists, pane is quiet
sleep 0.8
