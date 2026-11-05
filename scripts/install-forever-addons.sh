#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
STAGING="${WOW_COUCH_CONFIG}/addons-staging"
DEST="${WOW_ADDONS}"
mkdir -p "$STAGING" "$DEST"
cd "$STAGING"

CP_URL="https://github.com/seblindfors/ConsolePort/releases/download/3.3.13/ConsolePort-3.3.13.zip"
IM_URL="https://github.com/seblindfors/Immersion/releases/download/1.4.61/Immersion-1.4.61.zip"
FVO_URL="https://github.com/quinn-dougherty/forever-vo/releases/download/v0.1.10/forever-vo-v0.1.10-forever.zip"
[[ -f ConsolePort-3.3.13.zip ]] || curl -L --fail --retry 3 -o ConsolePort-3.3.13.zip "$CP_URL"
[[ -f Immersion-1.4.61.zip ]] || curl -L --fail --retry 3 -o Immersion-1.4.61.zip "$IM_URL"
[[ -f forever-vo-v0.1.10-forever.zip ]] || curl -L --fail --retry 3 -o forever-vo-v0.1.10-forever.zip "$FVO_URL"

# Forever Voiceover voice packs (shared CurseForge helper)
fetch_pack() {
  local project="$1"
  local path
  path="$(python3 "${REPO_ROOT}/scripts/python/curseforge_fetch.py" --project "$project" --staging "$STAGING")"
  PACK_ZIPS+=("$path")
}

PACK_ZIPS=()
fetch_pack 1705100  # Classic Quests
fetch_pack 1709884  # Classic Endgame
fetch_pack 1729567  # Classic Gossip
fetch_pack 1705094  # Forever Quests
fetch_pack 1729570  # Forever Gossip
fetch_pack 1729514  # Books

find "$DEST" -maxdepth 1 -type d \( \
  -name 'ConsolePort*' -o -name 'Immersion' -o -name 'ForeverVO' -o -name 'ForeverVO_Data*' \
\) -exec rm -rf {} + 2>/dev/null || true

unzip -o ConsolePort-3.3.13.zip -d "$DEST"
unzip -o Immersion-1.4.61.zip -d "$DEST"
unzip -o forever-vo-v0.1.10-forever.zip -d "$DEST"
for z in "${PACK_ZIPS[@]}"; do
  unzip -o "$z" -d "$DEST"
done

echo "Installed into $DEST:"
ls -1 "$DEST"
