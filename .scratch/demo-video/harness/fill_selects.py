#!/usr/bin/env python3
"""Fill the demo shoot folder with 80 near-identical files.

`make_demo_data.py` builds a 4-file Selects folder. That is too sparse for the
path-jump cut: the landing marker lands on row 1 of 4 and reads as decoration
rather than as "this is where you are". With 80 lookalike names the target sits
below the fold, scrollRowToVisible has to scroll to it, and the marker is the
only thing distinguishing the target row from its neighbours.

Run after make_demo_data.py:  python3 fill_selects.py [~/Studio]
"""
import datetime
import glob
import os
import shutil
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Studio")
DEST = os.path.join(ROOT, "Shoots", "2026-07 Studio Portraits", "Selects")
COUNT = 80

sources = sorted(glob.glob(os.path.join(DEST, "portrait-session-*.jpg")))
if not sources:
    sys.exit(f"no seed images in {DEST} — run make_demo_data.py first")

for i in range(1, COUNT + 1):
    target = os.path.join(DEST, f"portrait-session-{i:02d}.jpg")
    src = sources[i % len(sources)]
    if os.path.abspath(src) != os.path.abspath(target):
        shutil.copyfile(src, target)

# Spread the mtimes so the Date column is not a wall of identical values, and so
# the date sort puts the target somewhere in the middle rather than at an edge.
for path in glob.glob(os.path.join(DEST, "portrait-session-*.jpg")):
    n = int(os.path.basename(path)[17:19])
    t = datetime.datetime(2026, 7, 1 + (n % 28), 8 + (n % 11), (n * 7) % 60).timestamp()
    os.utime(path, (t, t))

print(f"{len(glob.glob(os.path.join(DEST, '*.jpg')))} files in {DEST}")
