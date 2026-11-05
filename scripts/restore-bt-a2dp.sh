#!/usr/bin/env bash
# Put Bluetooth headphones back on high-quality A2DP playback.
# Usage:
#   restore-bt-a2dp.sh           # restore now
#   restore-bt-a2dp.sh --defer N # restore after N seconds (default 45) unless cancelled
#   restore-bt-a2dp.sh --cancel  # cancel a pending deferred restore
set -euo pipefail
FLAG="${XDG_RUNTIME_DIR:-/tmp}/wow-dictate-a2dp-restore.pid"

cancel_pending() {
  if [[ -f "$FLAG" ]]; then
    local pid
    pid="$(cat "$FLAG" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$FLAG"
  fi
}

restore_now() {
  local card active profile
  card="$(pactl list cards short 2>/dev/null | awk '/bluez_card/{print $2; exit}')"
  [[ -n "${card:-}" ]] || return 0
  active="$(pactl list cards 2>/dev/null | awk -v c="$card" '
    $0 ~ "Name: "c {hit=1}
    hit && /Active Profile:/ {print $3; exit}
  ')"
  [[ "${active:-}" == headset-head-unit* ]] || return 0
  for profile in a2dp-sink a2dp-sink-sbc_xq a2dp-sink-sbc; do
    if pactl set-card-profile "$card" "$profile" 2>/dev/null; then
      echo "Restored ${card} → ${profile}" >&2
      return 0
    fi
  done
}

case "${1:-}" in
  --cancel)
    cancel_pending
    exit 0
    ;;
  --defer)
    secs="${2:-45}"
    cancel_pending
    (
      echo $BASHPID >"$FLAG"
      sleep "$secs"
      rm -f "$FLAG"
      restore_now
    ) >/dev/null 2>&1 &
    disown || true
    echo "A2DP restore scheduled in ${secs}s" >&2
    ;;
  *)
    cancel_pending
    restore_now
    ;;
esac
