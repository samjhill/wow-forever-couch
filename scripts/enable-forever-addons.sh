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
  Syndicator Baganator Leatrix_Plus Plater
  LoreForever LoreForever_Voice_Default LoreForever_Voice_Default_Alliance LoreForever_Voice_Default_Horde
  TheFishingLog
)
# Removed from couch stack (Immersion covers quest/gossip keys)
DISABLE_ADDONS=(
  DialogKey_Numy DialogKey_Aeonzara DialogKey
)

if [[ ! -d "$WTF" ]]; then
  echo "No WTF/Account yet. Log in / create a character, then re-run."
  exit 0
fi

# Forever AddOns.txt uses "Name: enabled|disabled" (not "enable Name").
sync_addons_file() {
  local f="$1"
  mkdir -p "$(dirname "$f")"
  ENABLE_LIST="${ADDONS[*]}" DISABLE_LIST="${DISABLE_ADDONS[*]}" python3 - "$f" <<'PY'
import os, pathlib, sys
path = pathlib.Path(sys.argv[1])
enable = os.environ.get("ENABLE_LIST", "").split()
disable = os.environ.get("DISABLE_LIST", "").split()
lines = path.read_text(encoding="utf-8", errors="replace").splitlines() if path.exists() else []
state = {}
order = []
for line in lines:
    s = line.strip()
    if not s or s.startswith("#"):
        continue
    if ": " in s:
        name, val = s.split(": ", 1)
    elif s.startswith("enable "):
        name, val = s[7:].strip(), "enabled"
    elif s.startswith("disable "):
        name, val = s[8:].strip(), "disabled"
    else:
        continue
    name = name.strip()
    val = val.strip().lower()
    if name not in state:
        order.append(name)
    state[name] = "enabled" if val.startswith("enable") else "disabled"
for name in enable:
    if name not in state:
        order.append(name)
    state[name] = "enabled"
for name in disable:
    if name not in state:
        order.append(name)
    state[name] = "disabled"
out = [f"{n}: {state[n]}" for n in order]
path.write_text("\n".join(out) + ("\n" if out else ""), encoding="utf-8")
print(f"updated {path} (enabled={sum(1 for v in state.values() if v=='enabled')}, disabled={sum(1 for v in state.values() if v=='disabled')})")
PY
}

shopt -s nullglob
is_account_tree() {
  local p="$1"
  [[ "$p" == *"/SavedVariables/"* || "$p" == *"/SavedVariables" ]] && return 1
  return 0
}
for f in "$WTF"/*/AddOns.txt "$WTF"/*/*/AddOns.txt "$WTF"/*/*/*/AddOns.txt; do
  is_account_tree "$f" || continue
  sync_addons_file "$f"
done
# Seed account-level AddOns.txt when missing
for acct in "$WTF"/*/; do
  [[ -d "$acct" ]] || continue
  base=$(basename "$acct")
  [[ "$base" == "SavedVariables" ]] && continue
  if [[ ! -f "${acct}AddOns.txt" ]]; then
    sync_addons_file "${acct}AddOns.txt"
  fi
done
rm -f "${WTF}/SavedVariables/AddOns.txt"

# Drop DialogKey from disk if still present
rm -rf "${WOW_ADDONS}/DialogKey_Numy" "${WOW_ADDONS}/DialogKey_Aeonzara" "${WOW_ADDONS}/DialogKey"

"${REPO_ROOT}/scripts/pin-voiceover-prefs.sh"
echo "Done. Reload UI (/reload) or relog for addons to load."
