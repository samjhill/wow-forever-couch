#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="${HOME}/.local/share/Steam"
export STEAM_COMPAT_DATA_PATH="${WOW_PREFIX}"
PROTON="${HOME}/.local/share/Steam/compatibilitytools.d/GE-Proton11-12/proton"
EXE="${STEAM_COMPAT_DATA_PATH}/pfx/drive_c/Program Files (x86)/Battle.net/Battle.net.exe"
if [[ ! -f "$EXE" ]]; then
  EXE=$(find "${STEAM_COMPAT_DATA_PATH}/pfx/drive_c" -name 'Battle.net.exe' 2>/dev/null | head -1 || true)
fi
if [[ -z "${EXE:-}" || ! -f "$EXE" ]]; then
  echo "Battle.net.exe not found. Run scripts/install-battlenet-desktop.sh from Desktop Mode first." >&2
  exit 1
fi
cd "$(dirname "$EXE")"
exec "$PROTON" run "$EXE"
