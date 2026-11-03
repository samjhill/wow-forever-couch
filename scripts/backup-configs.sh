#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
BASE="${WOW_COUCH_CONFIG}"
STAMP=$(date +%Y%m%d-%H%M%S)
DEST="${BASE}/backup-${STAMP}"
mkdir -p "$DEST/lutris" "$DEST/steam"
cp -a "${HOME}/.config/lutris/games" "$DEST/lutris/" 2>/dev/null || true
cp -a "${HOME}/.config/lutris/runners" "$DEST/lutris/" 2>/dev/null || true
# shortcuts
find "${HOME}/.local/share/Steam/userdata" -path '*/config/shortcuts.vdf' -exec cp -a {} "$DEST/steam/" \; 2>/dev/null || true
echo "Backup written to $DEST"
