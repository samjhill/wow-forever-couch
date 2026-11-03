#!/usr/bin/env python3
"""Print peak absolute sample and rough dBFS for a WAV; exit 1 if below silence floor."""
import sys
import wave
import math
import array

path = sys.argv[1]
floor_db = float(sys.argv[2]) if len(sys.argv) > 2 else -55.0
with wave.open(path, "rb") as w:
    nch, sw, rate, nframes, _, _ = w.getparams()
    raw = w.readframes(nframes)
if sw == 2:
    samples = array.array("h")
    samples.frombytes(raw)
elif sw == 4:
    samples = array.array("i")
    samples.frombytes(raw)
else:
    print(f"unsupported sample width {sw}", file=sys.stderr)
    sys.exit(2)
if not samples:
    print("empty wav", file=sys.stderr)
    sys.exit(1)
peak = max(abs(s) for s in samples)
full = float(1 << (8 * sw - 1))
db = -120.0 if peak == 0 else 20.0 * math.log10(peak / full)
print(f"peak={peak} dbfs={db:.1f} floor={floor_db}")
sys.exit(0 if db >= floor_db else 1)
