#!/usr/bin/env bash
# End-to-end dictation harness against a headless WoW chat mock (no Forever client).
#
# Covers:
#   - draft appears in the mock edit box
#   - second confirm sends
#   - cancel discards
#   - sticky say for solo / party-of-2
#   - sticky party for party-of-3+
#   - sticky raid
#   - DICTATE_CHANNEL slash override
#   - whisper WAV → draft → confirm (optional if model present)
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

STATE="${WOW_COUCH_CONFIG}/mock-wow-state.json"
FIFO="${WOW_COUCH_CONFIG}/mock-wow.fifo"
READY="${WOW_COUCH_CONFIG}/mock-wow.ready"
STATUS="${WOW_COUCH_CONFIG}/dictate-status.json"
LOG="${WOW_COUCH_CONFIG}/mock-wow-harness.log"
MOCK_PID=""
FAILS=0

pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*" >&2; FAILS=$((FAILS + 1)); }

cleanup() {
  if [[ -n "${MOCK_PID}" ]] && kill -0 "$MOCK_PID" 2>/dev/null; then
    printf '%s\n' '{"type":"quit"}' >"$FIFO" 2>/dev/null || true
    sleep 0.2
    kill "$MOCK_PID" 2>/dev/null || true
    wait "$MOCK_PID" 2>/dev/null || true
  fi
  rm -f "$READY"
}
trap cleanup EXIT

read_state() {
  python3 - "$STATE" <<'PY'
import json,sys
print(json.dumps(json.load(open(sys.argv[1]))))
PY
}

expect_json() {
  local label="$1"
  local py="$2"
  if python3 - "$STATE" <<PY
import json,sys
s=json.load(open(sys.argv[1]))
$py
PY
  then
    pass "$label"
  else
    fail "$label — state=$(read_state)"
  fi
}

set_group() {
  local size="$1"
  local raid="${2:-false}"
  python3 - "$FIFO" "$size" "$raid" <<'PY'
import json,sys
fifo, size, raid = sys.argv[1], int(sys.argv[2]), sys.argv[3].lower()=="true"
with open(fifo,"w") as f:
    f.write(json.dumps({"type":"set_group","size":size,"raid":raid})+"\n")
    f.flush()
PY
  sleep 0.1
}

echo "=== start mock WoW chat ===" | tee "$LOG"
rm -f "$STATE" "$READY"
[[ -p "$FIFO" ]] || mkfifo "$FIFO"
python3 "${REPO_ROOT}/scripts/mock-wow-chat.py" \
  --fifo "$FIFO" \
  --state "$STATE" \
  --ready-file "$READY" >>"$LOG" 2>&1 &
MOCK_PID=$!
export DICTATE_MOCK_FIFO="$FIFO"

for ((i = 0; i < 100; i++)); do
  [[ -f "$READY" && -f "$STATE" ]] && break
  sleep 0.05
done
[[ -f "$READY" ]] || { fail "mock did not become ready"; exit 1; }
pass "mock ready (pid=$MOCK_PID)"

echo "=== A: draft appears (solo sticky SAY) ==="
set_group 0 false
DICTATE_SEND_MODE=draft DICTATE_CHANNEL=auto \
  "${REPO_ROOT}/scripts/inject-wow-chat.sh" <<<'ready to pull'
sleep 0.15
expect_json "draft open on SAY" \
  'assert s["chat_open"] is True and s["channel"]=="SAY" and s["draft"]=="ready to pull"'

echo "=== B: confirm sends ==="
# Mirror daemon: status draft then confirm script
python3 - "$STATUS" <<'PY'
import json,sys,time
json.dump({"state":"draft","ts":time.time(),"detail":"ready to pull","send_mode":"draft","channel":"auto"}, open(sys.argv[1],"w"), indent=2)
PY
"${REPO_ROOT}/scripts/confirm-wow-chat.sh" confirm
sleep 0.15
expect_json "confirm delivered SAY message" \
  'assert s["chat_open"] is False and s["sent"] and s["sent"][-1]["channel"]=="SAY" and s["sent"][-1]["text"]=="ready to pull"'
grep -q '"state": "sent"' "$STATUS" && pass "dictate-status=sent" || fail "dictate-status not sent"

echo "=== C: cancel discards draft ==="
DICTATE_SEND_MODE=draft DICTATE_CHANNEL=auto \
  "${REPO_ROOT}/scripts/inject-wow-chat.sh" <<<'do not send this'
sleep 0.1
"${REPO_ROOT}/scripts/confirm-wow-chat.sh" cancel
sleep 0.1
expect_json "cancel cleared draft" \
  'assert s["chat_open"] is False and s["draft"]=="" and (not s["sent"] or s["sent"][-1]["text"]!="do not send this")'

echo "=== D: party-of-2 still SAY ==="
set_group 2 false
DICTATE_SEND_MODE=draft DICTATE_CHANNEL=auto \
  "${REPO_ROOT}/scripts/inject-wow-chat.sh" <<<'couch duo'
sleep 0.1
expect_json "party-of-2 draft on SAY" \
  'assert s["chat_open"] and s["channel"]=="SAY" and s["draft"]=="couch duo"'
"${REPO_ROOT}/scripts/confirm-wow-chat.sh" cancel >/dev/null

echo "=== E: party-of-3 sticky PARTY ==="
set_group 3 false
DICTATE_SEND_MODE=draft DICTATE_CHANNEL=auto \
  "${REPO_ROOT}/scripts/inject-wow-chat.sh" <<<'need healer'
sleep 0.1
expect_json "party-of-3 draft on PARTY" \
  'assert s["chat_open"] and s["channel"]=="PARTY" and s["draft"]=="need healer"'
"${REPO_ROOT}/scripts/confirm-wow-chat.sh" confirm >/dev/null
sleep 0.1
expect_json "party-of-3 sent PARTY" \
  'assert s["sent"][-1]["channel"]=="PARTY" and s["sent"][-1]["text"]=="need healer"'

echo "=== F: raid sticky RAID ==="
set_group 10 true
DICTATE_SEND_MODE=draft DICTATE_CHANNEL=auto \
  "${REPO_ROOT}/scripts/inject-wow-chat.sh" <<<'stack on star'
sleep 0.1
expect_json "raid draft on RAID" \
  'assert s["chat_open"] and s["channel"]=="RAID" and s["draft"]=="stack on star"'
"${REPO_ROOT}/scripts/confirm-wow-chat.sh" confirm >/dev/null
sleep 0.1
expect_json "raid sent RAID" \
  'assert s["sent"][-1]["channel"]=="RAID" and s["sent"][-1]["text"]=="stack on star"'

echo "=== G: DICTATE_CHANNEL=party override while solo ==="
set_group 0 false
DICTATE_SEND_MODE=draft DICTATE_CHANNEL=party \
  "${REPO_ROOT}/scripts/inject-wow-chat.sh" <<<'override party'
sleep 0.1
expect_json "override draft shows /p prefix + PARTY header" \
  'assert s["chat_open"] and s["draft"].startswith("/p ") and s["channel"]=="PARTY"'
"${REPO_ROOT}/scripts/confirm-wow-chat.sh" confirm >/dev/null
sleep 0.1
expect_json "override sent as PARTY body" \
  'assert s["sent"][-1]["channel"]=="PARTY" and s["sent"][-1]["text"]=="override party"'

echo "=== H: DICTATE_SEND_MODE=send auto-final-Enter ==="
set_group 0 false
DICTATE_SEND_MODE=send DICTATE_CHANNEL=say \
  "${REPO_ROOT}/scripts/inject-wow-chat.sh" <<<'autosend probe'
sleep 0.15
expect_json "autosend landed in SAY" \
  'assert (not s["chat_open"]) and s["sent"][-1]["channel"]=="SAY" and s["sent"][-1]["text"]=="autosend probe"'

echo "=== I: whisper WAV → draft → confirm (if model present) ==="
MODEL="${WHISPER_MODEL:-$HOME/.local/share/whisper/ggml-base.en.bin}"
SIM="${WOW_COUCH_CONFIG}/sim-dictation/phrase2.wav"
if [[ -f "$MODEL" ]]; then
  if [[ ! -s "$SIM" ]]; then
    mkdir -p "${WOW_COUCH_CONFIG}/sim-dictation"
    if command -v espeak-ng >/dev/null; then
      espeak-ng -v en-us -s 140 -w /tmp/mock-wow-espeak.wav "ready to pull when you are"
      ffmpeg -y -i /tmp/mock-wow-espeak.wav -ar 16000 -ac 1 "$SIM" >/dev/null 2>&1
    fi
  fi
  if [[ -s "$SIM" ]]; then
    set_group 0 false
    rm -f "$STATUS"
    DICTATE_SEND_MODE=draft DICTATE_CHANNEL=auto DICTATE_WAV="$SIM" \
      DICTATE_MOCK_FIFO="$FIFO" \
      "${REPO_ROOT}/scripts/dictate-push-to-talk.sh" >/tmp/mock-wow-dictate.out 2>&1 || true
    sleep 0.2
    if grep -q '"state": "draft"' "$STATUS" 2>/dev/null; then
      pass "whisper→draft status"
      expect_json "whisper draft visible in mock" \
        'assert s["chat_open"] and len(s["draft"])>0'
      "${REPO_ROOT}/scripts/confirm-wow-chat.sh" confirm >/dev/null
      sleep 0.15
      expect_json "whisper confirm sent" \
        'assert (not s["chat_open"]) and s["sent"] and len(s["sent"][-1]["text"])>0'
    else
      fail "whisper path did not reach draft ($(cat "$STATUS" 2>/dev/null || true))"
    fi
  else
    echo "WARN: no sim wav — skip whisper leg"
  fi
else
  echo "WARN: whisper model missing — skip whisper leg"
fi

echo
echo "Mock state summary:"
python3 - "$STATE" <<'PY'
import json,sys
s=json.load(open(sys.argv[1]))
print(f"  sent={len(s['sent'])} last={s['sent'][-1] if s['sent'] else None}")
print(f"  channel={s['channel']} chat_open={s['chat_open']} draft={s['draft']!r}")
PY

if [[ "$FAILS" -gt 0 ]]; then
  echo "Mock WoW harness: $FAILS failure(s)." >&2
  exit 1
fi
echo "Mock WoW harness passed."
