#!/usr/bin/env bash
# Record → whisper.cpp → clipboard → inject into WoW chat (Esc/Enter/type[/Enter]).
# DICTATE_NO_SEND=1 skips chat inject. DICTATE_WAV=/path skips mic.
# DICTATE_SEND_MODE=draft|send (default draft — second left grip confirms send).
# DICTATE_CHANNEL=auto|say|party|raid (manual override; auto uses CouchDictateRoute sticky).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
WAV="/tmp/wow-dictate.wav"
TXT="${WOW_COUCH_CONFIG}/last-dictation.txt"
STATUS="${WOW_COUCH_CONFIG}/dictate-status.json"
LOCK="/tmp/wow-dictate.lock"
SECS="${DICTATE_SECS:-6}"
WHISPER_BIN="${WHISPER_BIN:-$HOME/.local/bin/whisper-cli}"
MODEL="${WHISPER_MODEL:-$HOME/.local/share/whisper/ggml-base.en.bin}"
START_SND="${WOW_COUCH_CONFIG}/sounds/dictate-start.wav"
STOP_SND="${WOW_COUCH_CONFIG}/sounds/dictate-stop.wav"
DONE_SND="${WOW_COUCH_CONFIG}/sounds/dictate-done.wav"
INJECT="${REPO_ROOT}/scripts/inject-wow-chat.sh"
SEND_MODE="${DICTATE_SEND_MODE:-draft}"
CHANNEL="${DICTATE_CHANNEL:-auto}"
# Restore Bose/etc. to A2DP after capture (better game audio). Set 0 to stay on HFP.
RESTORE_A2DP="${DICTATE_RESTORE_A2DP:-1}"
SILENCE_DB="${DICTATE_SILENCE_DB:--45}"
# Keep Forever playable on the i5: Whisper defaults to all cores otherwise.
WHISPER_THREADS="${DICTATE_WHISPER_THREADS:-1}"
mkdir -p "${WOW_COUCH_CONFIG}/sounds"

nice_cmd() {
  # Best-effort low priority so transcription does not tank gamescope FPS.
  if command -v nice >/dev/null && command -v ionice >/dev/null; then
    nice -n 19 ionice -c3 "$@"
  elif command -v nice >/dev/null; then
    nice -n 19 "$@"
  else
    "$@"
  fi
}

if [[ ! -f "$START_SND" ]] && command -v ffmpeg >/dev/null; then
  ffmpeg -y -f lavfi -i "sine=f=880:d=0.12" -ar 44100 "$START_SND" 2>/dev/null || true
  ffmpeg -y -f lavfi -i "sine=f=660:d=0.12" -ar 44100 "$STOP_SND" 2>/dev/null || true
  ffmpeg -y -f lavfi -i "sine=f=1200:d=0.08" -ar 44100 "$DONE_SND" 2>/dev/null || true
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
  paplay "$f" >/dev/null 2>&1 || true
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
  # Prefer Bose HFP mic (or analog). Never record a *.monitor loopback.
  MIC_TARGET="$("${REPO_ROOT}/scripts/prefer-mic-source.sh" | tail -n1 || true)"
  if [[ -z "${MIC_TARGET:-}" || "$MIC_TARGET" == *.monitor ]]; then
    echo "No usable mic (Bose must allow Headset/HFP, or use analog mic-in)." >&2
    write_status "error" "no mic source"
    exit 3
  fi
  echo "Recording ${SECS}s from ${MIC_TARGET}..."
  # pw-record can take a few hundred ms to start after HFP switch
  sleep 0.3
  timeout "$SECS" pw-record --target "$MIC_TARGET" "$WAV" || true
  beep "$STOP_SND"
  if [[ "$RESTORE_A2DP" == "1" ]]; then
    "${REPO_ROOT}/scripts/restore-bt-a2dp.sh" || true
  fi
fi

if [[ ! -s "$WAV" ]]; then
  echo "No audio captured" >&2
  write_status "error" "no audio"
  exit 3
fi

# Guard: silence → Whisper hallucinates words like "you" / "thank you"
if ! python3 "${REPO_ROOT}/scripts/wav-energy.py" "$WAV" "$SILENCE_DB"; then
  echo "Capture was silent (wrong source or mic muted). Nothing sent." >&2
  write_status "error" "silent capture"
  printf '' > "$TXT"
  exit 3
fi

CONV="/tmp/wow-dictate-16k.wav"
nice_cmd ffmpeg -y -i "$WAV" -ar 16000 -ac 1 "$CONV" 2>/dev/null || CONV="$WAV"

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
# -t 1 / -bs 1 / -bo 1: greedy, single-thread — much kinder to Forever on 4c CPU
nice_cmd "$WHISPER_BIN" -t "$WHISPER_THREADS" -bs 1 -bo 1 -m "$MODEL" -f "$CONV" -nt -np \
  2>/dev/null > "$TXT" || true
cat "$TXT"

if command -v wl-copy >/dev/null; then
  wl-copy < "$TXT" || true
  echo "Copied to Wayland clipboard."
elif command -v xclip >/dev/null; then
  xclip -selection clipboard < "$TXT" || true
  echo "Copied to X clipboard."
else
  echo "Clipboard tool missing; text in $TXT"
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
    echo "Sent to WoW chat (Esc → Enter → type → Enter) channel=${CHANNEL}."
  else
    write_status "draft" "$TRIMMED"
    echo "Draft in WoW chat (Esc → Enter → type; left grip again to send) channel=${CHANNEL}."
  fi
  beep "$DONE_SND"
else
  write_status "inject_failed" "$TRIMMED"
  echo "Chat inject failed — text left on clipboard / $TXT" >&2
  beep "$DONE_SND"
  exit 4
fi
