#!/usr/bin/env bash
# Keep the Deck screen on while WoW is running.
# On battery, Desktop Mode blanks the panel after 60s without a desktop
# input event. Controller play and the login load do not reset that timer,
# so the screen sleeps until the power button wakes it.
set -euo pipefail

WAIT_SECS="${WOW_KEEP_AWAKE_WAIT_SECS:-1800}"

wow_running() {
  pgrep -f 'Wow\.exe' >/dev/null 2>&1
}

deadline=$((SECONDS + WAIT_SECS))
while (( SECONDS < deadline )); do
  wow_running && break
  sleep 2
done
wow_running || exit 0

if ! command -v kde-inhibit >/dev/null 2>&1; then
  echo "kde-inhibit missing; cannot hold the screen awake" >&2
  exit 0
fi

exec kde-inhibit --power --screenSaver -- bash -c 'while pgrep -f "Wow\\.exe" >/dev/null 2>&1; do sleep 5; done'
