#!/bin/zsh
# Landing-page product shots: one PNG per scene, in light and dark, from a real
# staged Diptychon.
#
#   ./shoot_landing.sh [light|dark|both]
#
# Needs Screen Recording + Accessibility for the app that owns this terminal.
#
# How the scenes are staged (each cost a run to learn):
#   - The app is cloned to Shots.app with its own bundle id, so its UserDefaults
#     domain is separate and Till's real workspace state is never touched.
#   - Pane folders, sort, view mode and the terminal come from a seeded
#     `workspaceState` JSON blob. That is deterministic; driving the panes by
#     keyboard was not (arrow timing, focus landing in search or filter).
#   - Only states with no persisted form are typed: staging panel, palette, undo.
#   - Synthetic cmd-V and unicode events never reach this app's text fields, but
#     raw key codes do. The key map below is for a German layout.
#   - Look up the window by pid: a real instance may be running.
#   - Capture with -R from the window bounds; -l would add shadow padding.
set -u
cd "$(dirname "$0")"

S=${S:-/tmp/dipt-shots}
LOG=${LOG:-$S/shoot.log}
: > $LOG
exec > >(tee -a $LOG) 2>&1
echo "== shoot_landing $(date '+%F %T') =="

APP=$S/Shots.app/Contents/MacOS/Diptychon
P=$S/poke
OUT=${OUT:-$S/out}
DOMAIN=com.till.diptychon-shots
TREE=${TREE:-$HOME/Studio}
SRC="$TREE/Inbox"
DST="$TREE/Clients/Website Redesign"
mkdir -p $OUT

[[ -x $APP ]] || { echo "no staged clone at $APP"; exit 1 }
[[ -x $P   ]] || { echo "no poke at $P"; exit 1 }
[[ -d $SRC ]] || { echo "no demo tree at $SRC"; exit 1 }
if [[ -x $S/axcheck ]] && [[ "$($S/axcheck)" != "axTrusted=true" ]]; then
  echo "STOP: no Accessibility right - synthetic keys are blocked."; exit 1
fi
screencapture -x -R100,100,40,40 $S/.permcheck.png 2>/dev/null || {
  echo "STOP: no Screen Recording right."; exit 1 }
rm -f $S/.permcheck.png
echo "preflight ok"

typeset -A KC=(a 0 b 11 c 8 d 2 e 14 f 3 g 5 h 4 i 34 j 38 k 40 l 37 m 46 n 45
               o 31 p 35 q 12 r 15 s 1 t 17 u 32 v 9 w 13 x 7 y 6 z 16)

# The app follows the system appearance; -AppleInterfaceStyle as a launch
# argument does not reach SwiftUI. So the dark pass flips the system for about
# a minute and always flips it back, including on abort.
SYS_DARK_BEFORE=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode')
set_dark() { osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $1" >/dev/null; sleep 1.5 }
restore_appearance() { set_dark $SYS_DARK_BEFORE }
trap restore_appearance EXIT

PID=""
guard() {
  local front=$($P front)
  [[ "$front" == "Diptychon $PID" ]] || { echo "ABORT: frontmost is '$front', staged pid is $PID"; kill $PID 2>/dev/null; exit 1 }
}
k() { guard; $P key "$@"; sleep ${DELAY:-0.4} }
typestr() { local s=$1 c i; for (( i=1; i<=${#s}; i++ )); do c=${s[i]}; guard; $P key ${KC[$c]}; sleep 0.08; done; sleep 0.4 }

seed() {   # seed <left-dir> <right-dir> <left-mode|-> <terminal:0|1> <staged...>
  python3 - "$@" <<'PY'
import json, subprocess, sys
left, right, mode, term = sys.argv[1:5]
staged = sys.argv[5:]
def pane(path, mode=None):
    p = {"directoryPath": path, "sort": {"column": "date", "ascending": False}}
    if mode and mode != "-":
        p["displayMode"] = mode
        if mode == "brief": p["briefColumns"] = 3
    return p
state = {"schemaVersion": 1, "left": pane(left, mode), "right": pane(right),
         "staging": staged, "terminalVisible": term == "1"}
blob = json.dumps(state).encode()
subprocess.run(["defaults", "write", "com.till.diptychon-shots",
                "workspaceState", "-data", blob.hex()], check=True)
PY
}

start() {  # start <light|dark>
  local mode=$1 style=()
  "$APP" -AppleLocale en_US -AppleLanguages "(en)" >$S/app-$mode.log 2>&1 &
  PID=$!
  local win=""
  for i in $(seq 1 20); do sleep 1; win=$($P winfo $PID) && [[ -n "$win" ]] && break; done
  [[ -n "$win" ]] || { echo "ABORT: no window after 20s"; kill $PID 2>/dev/null; exit 1 }
  local front=""
  for i in 1 2 3 4 5; do $P activate $PID; sleep 1.0; front=$($P front); [[ "$front" == "Diptychon $PID" ]] && break; done
  guard
}

stop() { kill $PID 2>/dev/null; PID=""; sleep 1.2 }

shot() {   # shot <name> <mode>
  # -l keeps the window's rounded corners and gives a transparent surround, -o
  # drops the shadow; the surround is then trimmed away. A -R region capture
  # would square the corners off and bake the desktop into them.
  local wid=$($P winfo $PID | awk '{print $1}')
  rm -f $OUT/$1-$2.png
  if screencapture -x -o -l$wid $OUT/$1-$2.png; then
    $S/trim $OUT/$1-$2.png $OUT/$1-$2.png >/dev/null
    echo "  ${1}-${2}.png"
  else
    echo "  FAILED ${1}-${2}"
  fi
}

run() {
  local m=$1
  echo "== $m =="
  [[ $m == dark ]] && set_dark true || set_dark false

  # 1 table / tags: the plain two-pane state, tag colours in the tag column
  seed "$SRC" "$DST" - 0; start $m
  shot table $m; cp $OUT/table-$m.png $OUT/tags-$m.png; echo "  tags-$m.png"
  k 125; shot move $m          # one row selected
  # palette over the dimmed window
  k 40 cmd; sleep 0.7; typestr "move"; sleep 0.5; shot palette $m; k 53; sleep 0.4
  # copy to the other panel, then undo it from the palette: catches the toast
  k 0 cmd; k 124 cmd opt; sleep 1.6
  k 40 cmd; sleep 0.7; typestr "undo"; sleep 0.5; k 36; sleep 0.8; shot undo $m
  stop

  # 2 hero: the full window with the sidebar, for the top of the page
  defaults write $DOMAIN sidebarVisible -bool YES
  defaults write $DOMAIN pinnedFolders -array "$TREE/Shoots" "$TREE/Clients" "$TREE/Dev"
  seed "$SRC" "$DST" - 0; start $m; k 125; sleep 0.4; shot hero $m; stop
  defaults write $DOMAIN sidebarVisible -bool NO

  # 3 brief view, three columns of names
  seed "$SRC" "$DST" brief 0; start $m; shot brief $m; stop

  # 3 column browser, one folder per column
  # the browser only grows a second column once a folder is picked, and that
  # selection has no persisted form - so walk two steps into it
  seed "$TREE/Clients" "$DST" columns 0; start $m
  k 125; sleep 0.5; k 124; sleep 0.5; k 125; sleep 0.6
  shot columns $m; stop

  # 4 embedded terminal
  seed "$SRC" "$DST" - 1; start $m; shot terminal $m; stop

  # 5 staging: seed the set, then open the panel (no persisted form for it)
  seed "$SRC" "$DST" - 0 "$SRC/hero-v3.png" "$SRC/contract-draft.pdf" "$SRC/logo-final.svg" "$SRC/budget-Q3.xlsx"
  start $m; k 11 cmd shift; sleep 0.8; shot stage $m; stop
  restore_appearance
}

case "${1:-both}" in
  light) run light ;;
  dark)  run dark ;;
  both)  run light; run dark ;;
  *) echo "usage: $0 [light|dark|both]"; exit 2 ;;
esac
echo "done -> $OUT"
