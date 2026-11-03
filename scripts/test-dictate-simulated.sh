#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
BASE="${REPO_ROOT}"
WOW_COUCH_CONFIG="${WOW_COUCH_CONFIG}"
DICTATE="${BASE}/scripts/dictate-push-to-talk.sh"
OUTDIR="${BASE}/config/sim-dictation"
mkdir -p "$OUTDIR"

PHRASE1="${1:-Looking for group for Deadmines}"
PHRASE2="${2:-Ready to pull when you are}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1" >&2; exit 2; }; }
need espeak-ng
need ffmpeg
need python3

synthesize() {
  local phrase="$1" wav="$2"
  local raw="${wav%.wav}-espeak.wav"
  espeak-ng -v en-us -s 140 -w "$raw" "$phrase"
  ffmpeg -y -i "$raw" -ar 16000 -ac 1 "$wav" 2>/dev/null
  rm -f "$raw"
}

normalize() {
  python3 -c 'import sys,re; print(re.sub(r"[^a-z0-9]+"," ", sys.stdin.read().lower()).strip())'
}

check_match() {
  local expected="$1" actual_file="$2"
  local exp_n act_n
  exp_n=$(printf '%s' "$expected" | normalize)
  act_n=$(normalize < "$actual_file")
  if [[ -z "$act_n" ]]; then
    echo "FAIL: empty transcript (expected: $expected)" >&2
    return 1
  fi
  # Accept if expected words mostly appear (base.en allows minor typos)
  python3 - "$exp_n" "$act_n" <<'PY'
import sys
exp, act = sys.argv[1].split(), sys.argv[2].split()
if not exp:
    raise SystemExit(1)
hits = sum(1 for w in exp if w in act)
# Also allow close substring match of the whole phrase
ok = hits >= max(1, (len(exp) + 1) // 2) or exp[0] in " ".join(act)
print(f"match_words={hits}/{len(exp)} expected={{{' '.join(exp)}}} got={{{' '.join(act)}}}")
raise SystemExit(0 if ok else 1)
PY
}

run_one() {
  local label="$1" phrase="$2"
  local wav="${OUTDIR}/${label}.wav"
  echo "=== $label ==="
  echo "Expected: $phrase"
  synthesize "$phrase" "$wav"
  DICTATE_WAV="$wav" "$DICTATE"
  local txt="${BASE}/config/last-dictation.txt"
  echo "Transcript file: $txt"
  echo "Actual: $(tr '\n' ' ' < "$txt")"
  check_match "$phrase" "$txt"
  cp -f "$txt" "${OUTDIR}/${label}.txt"
  echo "PASS: $label"
  echo
}

run_one phrase1 "$PHRASE1"
sleep 0.5
run_one phrase2 "$PHRASE2"
echo "All simulated dictation checks passed."
echo "Artifacts under $OUTDIR"
