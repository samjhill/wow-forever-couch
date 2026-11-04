#!/usr/bin/env bash
# Prefer dictation capture source: Bluetooth mic if connected, else PC analog mic-in.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

find_id_by_match() {
  local pat="$1"
  wpctl status 2>/dev/null | awk -v pat="$pat" '
    BEGIN{IGNORECASE=1}
    /Sources:/{in_src=1; next}
    in_src && /Filters:/{exit}
    in_src && $0 ~ /monitor/ {next}
    in_src && $0 ~ pat {
      if (match($0, /([0-9]+)\./, m)) { print m[1]; exit }
    }
  '
}

set_wpctl_source() {
  local id="$1"
  local kind="$2"
  wpctl set-default "$id"
  wpctl set-volume "$id" 1.0 2>/dev/null || true
  echo "Default source set to ${kind} id=${id}"
  wpctl status | awk '/Sources:/,/Filters:/'
}

set_pactl_source() {
  local name="$1"
  local kind="$2"
  pactl set-default-source "$name"
  pactl set-source-volume "$name" 100% 2>/dev/null || true
  echo "Default source (pactl ${kind}): $name"
  pactl get-default-source
}

# 1) Bluetooth capture (headset / hands-free / bluez)
BT_ID="$(find_id_by_match "bluez|bluetooth|headset|hands-?free")"
if [[ -n "${BT_ID:-}" ]]; then
  set_wpctl_source "$BT_ID" "bluetooth"
  exit 0
fi

BT_NAME="$(pactl list short sources 2>/dev/null | awk '
  BEGIN{IGNORECASE=1}
  $2 ~ /monitor/ {next}
  $2 ~ /bluez_input|bluez_source|bluetooth/ {print $2; exit}
')"
if [[ -n "${BT_NAME:-}" ]]; then
  set_pactl_source "$BT_NAME" "bluetooth"
  exit 0
fi

# 2) Built-in analog mic-in (RØDE / lav jack)
ID="$(find_id_by_match "Built-in Audio Analog Stereo")"
if [[ -z "${ID:-}" ]]; then
  ID="$(find_id_by_match "Analog Stereo")"
fi
if [[ -n "${ID:-}" ]]; then
  set_wpctl_source "$ID" "mic-in (built-in analog)"
  exit 0
fi

NAME="$(pactl list short sources 2>/dev/null | awk '/alsa_input.*analog-stereo/ && $2 !~ /monitor/ {print $2; exit}')"
if [[ -n "${NAME:-}" ]]; then
  set_pactl_source "$NAME" "mic-in"
  exit 0
fi

echo "No Bluetooth or built-in analog mic-in source found." >&2
exit 2
