#!/bin/zsh
# One-shot recorder for the path-jump cut. Assumes NO other Diptychon instance
# is running (synthetic keys go to the frontmost app — a second instance would
# eat them). Saves/restores the user's clipboard around the take.
set -e
zmodload zsh/datetime
cd "$(dirname "$0")"
P=./poke
APP=/Applications/Diptychon.app/Contents/MacOS/Diptychon
# A crowded folder on purpose: 80 near-identical filenames, target well below the
# fold. On a 3-file folder the marker is decoration; here it is the only thing that
# says where you landed — and NSTableViewFileList scrollRowToVisible has to scroll
# to it, so the "instant" jump visibly narrates itself.
TARGET="$HOME/Studio/Shoots/2026-07 Studio Portraits/Selects/portrait-session-58.jpg"
OUT="${1:-../jump-raw.mov}"
KEYLOG=keys_jump.log
: > $KEYLOG
rm -f "$OUT"        # screencapture refuses to overwrite and only warns on stderr

CLIP_BACKUP=$(mktemp); pbpaste > "$CLIP_BACKUP"
restore() { pbcopy < "$CLIP_BACKUP"; rm -f "$CLIP_BACKUP"; }
trap restore EXIT

# staged instance: DIPTYCHON_DIR pins the root AND disables state persistence,
# so this never touches the real workspaceState blob.
DIPTYCHON_DIR="$HOME/Studio" "$APP" \
  -sidebarVisible NO -rightPanelVisible YES -previewVisible NO -AppleLocale en-US &
PID=$!
echo "staged pid=$PID"
sleep 3.5

$P frame $PID 60 60 1380 776
sleep 0.8
$P activate $PID
sleep 0.6
# focus bootstrap — palette open/close hands first responder to the pane
$P key 40 cmd; sleep 0.7; $P key 53; sleep 0.7

printf '%s' "$TARGET" | pbcopy
sleep 0.3

screencapture -V 22 -R60,60,1380,776 "$OUT" &
CAPPID=$!
print -r -- "$EPOCHREALTIME	T0" >> $KEYLOG
sleep 0.9

KEYLOG=$KEYLOG STAGED_PID=$PID ./take_jump.sh

sleep 0.6
kill -INT $CAPPID 2>/dev/null || true
wait $CAPPID 2>/dev/null || true
sleep 1.0
kill $PID 2>/dev/null || true      # only the pid we launched — never by pattern
echo "wrote $OUT"
