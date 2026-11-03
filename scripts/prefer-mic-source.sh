#!/usr/bin/env bash
# Prefer PC analog mic-in for dictation (lav / wireless RX 3.5mm → motherboard mic jack).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

find_id_by_match() {
  local pat="$1"
  wpctl status 2>/dev/null | awk -v pat="$pat" '
    BEGIN{IGNORECASE=1}
    /Sources:/{in_src=1; next}
    in_src && /Filters:/{exit}
    in_src && $0 ~ pat {
      if (match($0, /([0-9]+)\./, m)) { print m[1]; exit }
    }
  '
}

ID="$(find_id_by_match "Built-in Audio Analog Stereo")"
if [[ -z "${ID:-}" ]]; then
  ID="$(find_id_by_match "Analog Stereo")"
fi
if [[ -z "${ID:-}" ]]; then
  NAME="$(pactl list short sources 2>/dev/null | awk '/alsa_input.*analog-stereo/ && $2 !~ /monitor/ {print $2; exit}')"
  if [[ -n "${NAME:-}" ]]; then
    pactl set-default-source "$NAME"
    pactl set-source-volume "$NAME" 100% 2>/dev/null || true
    echo "Default source (pactl mic-in): $NAME"
    pactl get-default-source
    exit 0
  fi
  echo "No built-in analog mic-in source found." >&2
  exit 2
fi

wpctl set-default "$ID"
wpctl set-volume "$ID" 1.0 2>/dev/null || true
echo "Default source set to mic-in (built-in analog) id=$ID"
wpctl status | awk '/Sources:/,/Filters:/'
