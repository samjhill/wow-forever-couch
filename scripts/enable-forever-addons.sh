#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
# WOW_FOREVER provided by lib.sh
WTF="${WOW_FOREVER}/WTF/Account"
ADDONS=(
  ConsolePort ConsolePort_Bar ConsolePort_Config ConsolePort_Cursor
  ConsolePort_Keyboard ConsolePort_Menu ConsolePort_Rings ConsolePort_Target ConsolePort_World
  Immersion ForeverVO
  ForeverVO_Data_Classic_Quests ForeverVO_Data_Classic_Endgame ForeverVO_Data_Classic_Gossip
  ForeverVO_Data_Forever_Quests ForeverVO_Data_Forever_Gossip ForeverVO_Data_Books
  CouchDictateRoute
  # QoL install set (Forever-tagged); staged addons intentionally omitted
  Syndicator Baganator Leatrix_Plus Plater DialogKey_Numy
  LoreForever LoreForever_Voice_Default LoreForever_Voice_Default_Alliance LoreForever_Voice_Default_Horde
  TheFishingLog
)

if [[ ! -d "$WTF" ]]; then
  echo "No WTF/Account yet. Log in / create a character, then re-run."
  exit 0
fi

enable_file() {
  local f="$1"
  mkdir -p "$(dirname "$f")"
  local existing=""
  [[ -f "$f" ]] && existing=$(cat "$f")
  {
    printf '%s\n' "$existing"
    for a in "${ADDONS[@]}"; do
      grep -qx "enable $a" <<<"$existing" 2>/dev/null || echo "enable $a"
    done
  } | awk 'NF && !seen[$0]++' > "${f}.tmp"
  mv "${f}.tmp" "$f"
  echo "updated $f"
}

shopt -s nullglob
# Account-level and character-level AddOns.txt (skip WTF/Account/SavedVariables)
is_account_tree() {
  local p="$1"
  [[ "$p" == *"/SavedVariables/"* || "$p" == *"/SavedVariables" ]] && return 1
  return 0
}
for f in "$WTF"/*/AddOns.txt "$WTF"/*/*/AddOns.txt; do
  is_account_tree "$f" || continue
  enable_file "$f"
done
# If only account dirs exist with no AddOns.txt yet, seed account-level
for acct in "$WTF"/*/; do
  [[ -d "$acct" ]] || continue
  base=$(basename "$acct")
  [[ "$base" == "SavedVariables" ]] && continue
  if [[ ! -f "${acct}AddOns.txt" ]]; then
    enable_file "${acct}AddOns.txt"
  fi
done
# Remove mistaken enable file if we ever wrote under Account/SavedVariables
rm -f "${WTF}/SavedVariables/AddOns.txt"

"${REPO_ROOT}/scripts/pin-voiceover-prefs.sh"
echo "Done. Reload UI (/reload) or relog for addons to load."
