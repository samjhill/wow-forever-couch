#!/usr/bin/env bash
# Record → whisper.cpp → clipboard → inject into WoW chat (Esc/Enter/type[/Enter]).
# DICTATE_NO_SEND=1 skips chat inject. DICTATE_WAV=/path skips mic.
# DICTATE_SEND_MODE=send|draft (default send — release R3/grip to finish + send).
# DICTATE_HOLD=1 (daemon default): record until /tmp/wow-dictate.stop or DICTATE_MAX_SECS.
# DICTATE_HOLD=0: fixed DICTATE_SECS capture (CLI / harness).
# DICTATE_CHANNEL=auto|say|party|raid (manual override; auto uses CouchDictateRoute sticky).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
WAV="/tmp/wow-dictate.wav"
TXT="${WOW_COUCH_CONFIG}/last-dictation.txt"
STATUS="${WOW_COUCH_CONFIG}/dictate-status.json"
LOCK="/tmp/wow-dictate.lock"
STOP_FILE="${DICTATE_STOP_FILE:-/tmp/wow-dictate.stop}"
REC_PID_FILE="${DICTATE_REC_PID_FILE:-/tmp/wow-dictate.rec.pid}"
HOLD="${DICTATE_HOLD:-0}"
SECS="${DICTATE_SECS:-4}"
MAX_SECS="${DICTATE_MAX_SECS:-30}"
WHISPER_BIN="${WHISPER_BIN:-$HOME/.local/bin/whisper-cli}"
# tiny.en ≈ 1.7s on this box vs base.en ≈ 4–6s
MODEL="${WHISPER_MODEL:-$HOME/.local/share/whisper/ggml-tiny.en.bin}"
# Fall back to base if tiny not installed yet
if [[ ! -f "$MODEL" && -f "$HOME/.local/share/whisper/ggml-base.en.bin" ]]; then
  MODEL="$HOME/.local/share/whisper/ggml-base.en.bin"
fi
START_SND="${WOW_COUCH_CONFIG}/sounds/dictate-start.wav"
STOP_SND="${WOW_COUCH_CONFIG}/sounds/dictate-stop.wav"
DONE_SND="${WOW_COUCH_CONFIG}/sounds/dictate-done.wav"
INJECT="${REPO_ROOT}/scripts/inject-wow-chat.sh"
SEND_MODE="${DICTATE_SEND_MODE:-send}"
CHANNEL="${DICTATE_CHANNEL:-auto}"
# Defer A2DP restore so back-to-back dictation stays on HFP (faster). 0 = leave on HFP.
RESTORE_A2DP_DEFER="${DICTATE_RESTORE_A2DP_DEFER:-45}"
SILENCE_DB="${DICTATE_SILENCE_DB:--45}"
# 2 threads finishes tiny ~1.7s; still nicer than saturating all 4 cores.
WHISPER_THREADS="${DICTATE_WHISPER_THREADS:-2}"
mkdir -p "${WOW_COUCH_CONFIG}/sounds"

nice_cmd() {
  if command -v nice >/dev/null && command -v ionice >/dev/null; then
    nice -n 10 ionice -c3 "$@"
  elif command -v nice >/dev/null; then
    nice -n 10 "$@"
  else
    "$@"
  fi
}

if [[ ! -f "$START_SND" ]] && command -v ffmpeg >/dev/null; then
  ffmpeg -y -f lavfi -i "sine=f=880:d=0.08" -ar 44100 "$START_SND" 2>/dev/null || true
  ffmpeg -y -f lavfi -i "sine=f=660:d=0.08" -ar 44100 "$STOP_SND" 2>/dev/null || true
  ffmpeg -y -f lavfi -i "sine=f=1200:d=0.06" -ar 44100 "$DONE_SND" 2>/dev/null || true
fi

write_status() {
  local state="$1"
  local extra="${2:-}"
  python3 - "$STATUS" "$state" "$TXT" "$extra" "$SEND_MODE" "$CHANNEL" <<'PY'
import json, sys, time
path, state, txt, extra, mode, channel = sys.argv[1:7]
data = {
    "state": state,
    "ts": time.time(),
    "transcript_path": txt,
    "send_mode": mode,
    "channel": channel,
}
if extra:
    data["detail"] = extra
json.dump(data, open(path, "w"), indent=2)
print(f"status={state}", flush=True)
PY
}

beep() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  # Non-blocking — don't add latency to the pipeline
  paplay "$f" >/dev/null 2>&1 &
}

if [[ ! -x "$WHISPER_BIN" ]]; then
  for c in "$HOME/.local/bin/whisper-cli" whisper-cli whisper-cpp; do
    if command -v "$c" >/dev/null 2>&1; then
      WHISPER_BIN=$(command -v "$c")
      break
    fi
  done
fi

exec 9>"$LOCK"
if ! flock -n 9; then
  echo "Dictation already running; ignoring." >&2
  write_status "busy" "lock held"
  exit 0
fi
trap 'flock -u 9 2>/dev/null || true' EXIT

write_status "recording"
beep "$START_SND"

if [[ -n "${DICTATE_WAV:-}" ]]; then
  if [[ ! -s "$DICTATE_WAV" ]]; then
    echo "DICTATE_WAV missing or empty: $DICTATE_WAV" >&2
    write_status "error" "missing DICTATE_WAV"
    exit 3
  fi
  echo "Using simulated/replay WAV: $DICTATE_WAV"
  cp -f "$DICTATE_WAV" "$WAV"
else
  # Cancel pending A2DP restore — stay on HFP for this capture.
  "${REPO_ROOT}/scripts/restore-bt-a2dp.sh" --cancel || true
  MIC_TARGET="$("${REPO_ROOT}/scripts/prefer-mic-source.sh" | tail -n1 || true)"
  if [[ -z "${MIC_TARGET:-}" || "$MIC_TARGET" == *.monitor ]]; then
    echo "No usable mic (Bose must allow Headset/HFP, or use analog mic-in)." >&2
    write_status "error" "no mic source"
    exit 3
  fi
  # Record 16 kHz mono — Whisper-ready, skips ffmpeg convert
  if [[ "$HOLD" == "1" ]]; then
    if [[ -f "$STOP_FILE" ]]; then
      echo "Released before capture started — aborting."
      write_status "done" "released before record"
      beep "$STOP_SND"
      exit 0
    fi
    echo "Hold-to-talk from ${MIC_TARGET} (release bind / max ${MAX_SECS}s)..."
    rm -f "$REC_PID_FILE"
    pw-record --rate 16000 --channels 1 --format s16 --target "$MIC_TARGET" "$WAV" &
    REC_PID=$!
    echo "$REC_PID" > "$REC_PID_FILE"
    start_ts=$(date +%s)
    while kill -0 "$REC_PID" 2>/dev/null; do
      if [[ -f "$STOP_FILE" ]]; then
        break
      fi
      now_ts=$(date +%s)
      if (( now_ts - start_ts >= MAX_SECS )); then
        echo "Max hold ${MAX_SECS}s reached."
        break
      fi
      sleep 0.05
    done
    if kill -0 "$REC_PID" 2>/dev/null; then
      kill -INT "$REC_PID" 2>/dev/null || kill "$REC_PID" 2>/dev/null || true
      wait "$REC_PID" 2>/dev/null || true
    fi
    rm -f "$REC_PID_FILE" "$STOP_FILE"
  else
    echo "Recording ${SECS}s from ${MIC_TARGET}..."
    timeout "$SECS" pw-record --rate 16000 --channels 1 --format s16 --target "$MIC_TARGET" "$WAV" || true
  fi
  beep "$STOP_SND"
  if [[ "${RESTORE_A2DP_DEFER}" != "0" ]]; then
    "${REPO_ROOT}/scripts/restore-bt-a2dp.sh" --defer "$RESTORE_A2DP_DEFER" || true
  fi
fi

if [[ ! -s "$WAV" ]]; then
  echo "No audio captured" >&2
  write_status "error" "no audio"
  exit 3
fi

if ! python3 "${REPO_ROOT}/scripts/wav-energy.py" "$WAV" "$SILENCE_DB"; then
  echo "Capture was silent (wrong source or mic muted). Nothing sent." >&2
  write_status "error" "silent capture"
  printf '' > "$TXT"
  exit 3
fi

# Already 16k mono from pw-record; only convert replays / odd captures
CONV="$WAV"
rate="$(ffprobe -v error -show_entries stream=sample_rate -of csv=p=0 "$WAV" 2>/dev/null || echo "")"
ch="$(ffprobe -v error -show_entries stream=channels -of csv=p=0 "$WAV" 2>/dev/null || echo "")"
if [[ "$rate" != "16000" || "$ch" != "1" ]]; then
  CONV="/tmp/wow-dictate-16k.wav"
  nice_cmd ffmpeg -y -i "$WAV" -ar 16000 -ac 1 "$CONV" 2>/dev/null || CONV="$WAV"
fi

if [[ ! -f "$MODEL" ]]; then
  echo "Model missing: $MODEL — run scripts/setup-whisper.sh" >&2
  write_status "error" "missing model"
  exit 2
fi
if [[ ! -e "$WHISPER_BIN" ]]; then
  echo "whisper binary missing — run scripts/setup-whisper.sh" >&2
  write_status "error" "missing whisper"
  exit 2
fi

write_status "transcribing"
nice_cmd "$WHISPER_BIN" -t "$WHISPER_THREADS" -bs 1 -bo 1 -m "$MODEL" -f "$CONV" -nt -np \
  2>/dev/null > "$TXT" || true
cat "$TXT"

if command -v wl-copy >/dev/null; then
  wl-copy < "$TXT" || true
elif command -v xclip >/dev/null; then
  xclip -selection clipboard < "$TXT" || true
fi

TRIMMED="$(tr '\n\r\t' ' ' < "$TXT" | sed -E 's/  +/ /g; s/^ //; s/ $//')"
if [[ -z "$TRIMMED" ]]; then
  write_status "done" "empty transcript — not sent"
  echo "Empty transcript; nothing sent to chat."
  beep "$DONE_SND"
  exit 0
fi

if [[ "${DICTATE_NO_SEND:-0}" == "1" ]]; then
  write_status "done" "DICTATE_NO_SEND — clipboard only"
  echo "DICTATE_NO_SEND=1 — skipped WoW chat inject."
  beep "$DONE_SND"
  exit 0
fi

write_status "injecting" "$TRIMMED"
export DICTATE_SEND_MODE="$SEND_MODE"
export DICTATE_CHANNEL="$CHANNEL"
if "$INJECT" < "$TXT"; then
  SEND_MODE_LC="$(printf '%s' "$SEND_MODE" | tr '[:upper:]' '[:lower:]')"
  if [[ "$SEND_MODE_LC" == "send" || "$SEND_MODE_LC" == "auto" ]]; then
    write_status "sent" "$TRIMMED"
    echo "Sent to WoW chat channel=${CHANNEL}."
  else
    write_status "draft" "$TRIMMED"
    echo "Draft in WoW chat (DICTATE_SEND_MODE=draft) channel=${CHANNEL}."
  fi
  beep "$DONE_SND"
else
  write_status "inject_failed" "$TRIMMED"
  echo "Chat inject failed — text left on clipboard / $TXT" >&2
  beep "$DONE_SND"
  exit 4
fi
