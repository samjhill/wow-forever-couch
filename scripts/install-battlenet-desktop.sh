#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
export DISPLAY="${DISPLAY:-:0}"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="${HOME}/.local/share/Steam"
export STEAM_COMPAT_DATA_PATH="${WOW_PREFIX}"
PROTON="${HOME}/.local/share/Steam/compatibilitytools.d/GE-Proton11-12/proton"
SETUP="${HOME}/Downloads/Battle.net-Setup.exe"
mkdir -p "$STEAM_COMPAT_DATA_PATH"
if [[ ! -f "$SETUP" ]]; then
  $REPO_ROOT/scripts/download-battlenet-installer.sh
fi
if [[ ! -x "$PROTON" ]]; then
  $REPO_ROOT/scripts/install-ge-proton.sh
fi
echo "Launching Battle.net Setup on DISPLAY=$DISPLAY"
echo "Click Continue (English US) → install → then launch scripts/launch-battlenet-proton.sh to log in."
exec "$PROTON" run "$SETUP"
