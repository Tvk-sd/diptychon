#!/usr/bin/env python3
"""keys.log (epoch<TAB>label, first line = T0 of recording start) → schedule.tsv
(start<TAB>end<TAB>label, video-relative). Merges rapid same-label repeats into
one badge with a ×N suffix. LAG = screencapture startup latency (calibrated)."""
import sys

log, out, lag = sys.argv[1], sys.argv[2], float(sys.argv[3])
events = []
t0 = None
for line in open(log):
    ts, label = line.rstrip("\n").split("\t", 1)
    ts = float(ts)
    if label == "T0":
        t0 = ts
        continue
    events.append([ts - t0 - lag, label])

# merge consecutive same-label events with gaps < 0.6s
merged = []
for t, label in events:
    if merged and merged[-1][2] == label and t - merged[-1][1] < 0.75:
        merged[-1][1] = t
        merged[-1][3] += 1
    else:
        merged.append([t, t, label, 1])

lines = []
for i, (first, last, label, count) in enumerate(merged):
    nxt = merged[i + 1][0] if i + 1 < len(merged) else last + 2.0
    end = min(last + 1.4, max(last + 0.7, nxt - 0.06))
    text = f"{label}  ×{count}" if count > 1 else label
    lines.append(f"{first:.2f}\t{end:.2f}\t{text}")
open(out, "w").write("\n".join(lines) + "\n")
print(f"{len(lines)} badges → {out}")
