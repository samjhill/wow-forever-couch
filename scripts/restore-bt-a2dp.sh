#!/usr/bin/env bash
# After dictation, put Bluetooth headphones back on high-quality A2DP playback.
set -euo pipefail
card="$(pactl list cards short 2>/dev/null | awk '/bluez_card/{print $2; exit}')"
[[ -n "${card:-}" ]] || exit 0
active="$(pactl list cards 2>/dev/null | awk -v c="$card" '
  $0 ~ "Name: "c {hit=1}
  hit && /Active Profile:/ {print $3; exit}
')"
[[ "${active:-}" == headset-head-unit* ]] || exit 0
for profile in a2dp-sink a2dp-sink-sbc_xq a2dp-sink-sbc; do
  if pactl set-card-profile "$card" "$profile" 2>/dev/null; then
    echo "Restored ${card} → ${profile}" >&2
    exit 0
  fi
done
exit 0
