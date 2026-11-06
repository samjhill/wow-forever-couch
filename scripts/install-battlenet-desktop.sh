#!/usr/bin/env bash
# Silent Battle.net install into $WOW_PREFIX under GE-Proton.
# The setup exe launches the launcher and does not exit; we wait for Battle.net.exe
# then stop the install/launcher processes so Forever install can pass --game=WoWF.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

export DISPLAY="${DISPLAY:-:0}"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="${HOME}/.local/share/Steam"
export STEAM_COMPAT_DATA_PATH="${WOW_PREFIX}"
SETUP="${HOME}/Downloads/Battle.net-Setup.exe"
WAIT_SECS="${WOW_BNET_INSTALL_WAIT_SECS:-600}"

mkdir -p "$STEAM_COMPAT_DATA_PATH"

EXISTING="$(find_battlenet_exe || true)"
if [[ -n "${EXISTING:-}" && -f "$EXISTING" ]]; then
  echo "Battle.net already present: $EXISTING"
  exit 0
fi

if [[ ! -f "$SETUP" ]]; then
  "${REPO_ROOT}/scripts/download-battlenet-installer.sh"
fi

if [[ -z "${WOW_PROTON:-}" || ! -x "$WOW_PROTON" ]]; then
  "${REPO_ROOT}/scripts/install-ge-proton.sh"
  # Re-source resolver after install-ge-proton may have added a new tool.
  WOW_PROTON="$(resolve_ge_proton)"
fi
if [[ -z "${WOW_PROTON:-}" || ! -x "$WOW_PROTON" ]]; then
  echo "GE-Proton not found under ${STEAM_COMPAT_TOOLS_DIR}" >&2
  exit 1
fi

echo "Silent-installing Battle.net on DISPLAY=$DISPLAY (Proton: $WOW_PROTON)"
echo "Args: --lang=enUS --installpath=\"C:\\Program Files (x86)\\Battle.net\""

# Background: installer starts launcher and never returns.
"$WOW_PROTON" run "$SETUP" --lang=enUS --installpath="C:\Program Files (x86)\Battle.net" &
INSTALL_PID=$!

deadline=$((SECONDS + WAIT_SECS))
EXE=""
while (( SECONDS < deadline )); do
  EXE="$(find_battlenet_exe || true)"
  if [[ -n "${EXE:-}" && -f "$EXE" ]]; then
    echo "Battle.net.exe ready: $EXE"
    break
  fi
  if ! kill -0 "$INSTALL_PID" 2>/dev/null; then
    wait "$INSTALL_PID" || true
    EXE="$(find_battlenet_exe || true)"
    break
  fi
  sleep 3
done

if [[ -z "${EXE:-}" || ! -f "$EXE" ]]; then
  echo "Timed out waiting for Battle.net.exe under $WOW_PREFIX (waited ${WAIT_SECS}s)." >&2
  echo "Re-run from Desktop Mode or check the Proton prefix." >&2
  kill "$INSTALL_PID" 2>/dev/null || true
  exit 1
fi

# Stop setup/launcher so the next step can launch with --game=WoWF --install.
kill "$INSTALL_PID" 2>/dev/null || true
pkill -f 'Battle\.net-Setup\.exe|Battle\.net\.exe' 2>/dev/null || true
sleep 2
echo "Battle.net installed. Next: Forever client install (or launch Battle.net)."
