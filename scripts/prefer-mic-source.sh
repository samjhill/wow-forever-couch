#!/usr/bin/env bash
# Prefer a real microphone for dictation (never a *.monitor loopback).
#
# Order:
#   1) Bluetooth headset mic — switch Bose/etc. from A2DP → HFP/HSP if needed
#   2) Built-in analog mic-in (RØDE jack)
#
# Prints the PipeWire/Pulse source name on stdout (last line) for pw-record --target.
# Env:
#   DICTATE_BT_PROFILE=headset-head-unit|headset-head-unit-cvsd  (default mSBC)
#   DICTATE_KEEP_HFP=1  leave headset profile after selection (default: leave as-is)
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

BT_PROFILE="${DICTATE_BT_PROFILE:-headset-head-unit}"

log() { echo "$*" >&2; }

is_monitor() {
  [[ "$1" == *.monitor ]] || [[ "$1" == *".monitor."* ]]
}

wait_for_bt_input() {
  local i name
  for i in $(seq 1 25); do
    name="$(pactl list short sources 2>/dev/null | awk '
      BEGIN{IGNORECASE=1}
      $2 ~ /monitor/ {next}
      $2 ~ /^bluez_input\.|^bluez_source\./ {print $2; exit}
    ')"
    if [[ -n "${name:-}" ]]; then
      printf '%s\n' "$name"
      return 0
    fi
    sleep 0.2
  done
  return 1
}

ensure_bt_headset_profile() {
  local card profile
  card="$(pactl list cards short 2>/dev/null | awk '/bluez_card/{print $2; exit}')"
  [[ -n "${card:-}" ]] || return 1

  local active
  active="$(pactl list cards 2>/dev/null | awk -v c="$card" '
    $0 ~ "Name: "c {hit=1}
    hit && /Active Profile:/ {print $3; exit}
  ')"

  # Already HFP/HSP
  if [[ "${active:-}" == headset-head-unit* ]]; then
    log "Bluetooth card ${card} already on ${active}"
    return 0
  fi

  # Prefer mSBC, fall back to CVSD
  for profile in "$BT_PROFILE" headset-head-unit headset-head-unit-cvsd; do
    if pactl set-card-profile "$card" "$profile" 2>/dev/null; then
      log "Switched ${card} ${active:-?} → ${profile} (headset mic)"
      return 0
    fi
  done
  log "Could not switch ${card} to headset profile (active=${active:-unknown})"
  return 1
}

set_default_source() {
  local name="$1"
  local kind="$2"
  if is_monitor "$name"; then
    log "Refusing monitor source: $name"
    return 1
  fi
  pactl set-default-source "$name" 2>/dev/null || true
  pactl set-source-volume "$name" 100% 2>/dev/null || true
  # Also try wpctl by matching description when possible
  log "Capture source (${kind}): $name"
  printf '%s\n' "$name"
}

# --- 1) Bluetooth headset mic ---
if pactl list cards short 2>/dev/null | grep -q bluez_card; then
  if ensure_bt_headset_profile; then
    if BT_SRC="$(wait_for_bt_input)"; then
      set_default_source "$BT_SRC" "bluetooth-headset"
      exit 0
    fi
    log "Headset profile up but no bluez_input source yet"
  fi
fi

# --- 2) Analog mic-in ---
ANALOG="$(pactl list short sources 2>/dev/null | awk '
  $2 ~ /^alsa_input\..*analog/ && $2 !~ /monitor/ {print $2; exit}
')"
if [[ -n "${ANALOG:-}" ]]; then
  set_default_source "$ANALOG" "mic-in"
  exit 0
fi

# --- 3) Any non-monitor input ---
ANY="$(pactl list short sources 2>/dev/null | awk '
  $2 !~ /monitor/ && $2 ~ /input|source/ {print $2; exit}
')"
if [[ -n "${ANY:-}" ]]; then
  set_default_source "$ANY" "fallback-input"
  exit 0
fi

log "No usable microphone source found (Bose must be on Headset/HFP, or plug analog mic-in)."
exit 2
