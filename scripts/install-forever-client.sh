#!/usr/bin/env bash
# Open Battle.net on the WoW Forever install page and wait until the client tree exists.
#
# Login cannot be automated — leave the window open, sign in if asked, click Install
# only if the page still shows a button. Polls $WOW_FOREVER (does not wait on Proton).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

WAIT_SECS="${WOW_FOREVER_INSTALL_WAIT_SECS:-14400}"  # 4h default for large downloads
HEARTBEAT_SECS="${WOW_FOREVER_INSTALL_HEARTBEAT_SECS:-60}"

if forever_client_ready; then
  echo "Forever client already present: $WOW_FOREVER"
  exit 0
fi

EXE="$(find_battlenet_exe || true)"
if [[ -z "${EXE:-}" || ! -f "$EXE" ]]; then
  echo "Battle.net.exe missing — installing launcher first…"
  "${REPO_ROOT}/scripts/install-battlenet-desktop.sh"
fi

echo "Opening Battle.net on WoW Forever install (--game=WoWF --install)."
echo "Log in if asked (and approve authenticator). Leave the window open until Forever finishes."

# Skip the launch-hook repo sync while we only care about the client download.
WOW_COUCH_LAUNCH_SYNC=0 \
  "${REPO_ROOT}/scripts/launch-battlenet-proton.sh" --game=WoWF --install &
disown || true

deadline=$((SECONDS + WAIT_SECS))
last_beat=$SECONDS
while (( SECONDS < deadline )); do
  if forever_client_ready; then
    echo "Forever client ready: $WOW_FOREVER"
    exit 0
  fi
  if (( SECONDS - last_beat >= HEARTBEAT_SECS )); then
    echo "Still waiting for Forever under $WOW_FOREVER … ($(( (deadline - SECONDS) / 60 ))m left)"
    last_beat=$SECONDS
  fi
  sleep 5
done

echo "Timed out after ${WAIT_SECS}s waiting for Forever at $WOW_FOREVER" >&2
echo "Install Forever in Battle.net, then re-run bootstrap or:" >&2
echo "  ${REPO_ROOT}/scripts/install-forever-client.sh" >&2
exit 1
