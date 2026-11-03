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

# Forever Voiceover voice packs (CurseForge public list + ForgeCDN)
fetch_pack() {
  local project="$1"
  local meta file_id file_name file_len hi lo url have
  meta=$(curl -sL --fail \
    -H "Accept: application/json" -H "User-Agent: wow-forever-couch-fvo" \
    "https://www.curseforge.com/api/v1/mods/${project}/files?pageSize=20&sortField=1&sortOrder=desc")
  file_id=$(printf '%s' "$meta" | python3 -c 'import json,sys; files=json.load(sys.stdin)["data"]; rel=[f for f in files if f.get("releaseType")==1] or files; rel.sort(key=lambda f: f.get("dateCreated") or "", reverse=True); print(rel[0]["id"])')
  file_name=$(printf '%s' "$meta" | python3 -c 'import json,sys; files=json.load(sys.stdin)["data"]; rel=[f for f in files if f.get("releaseType")==1] or files; rel.sort(key=lambda f: f.get("dateCreated") or "", reverse=True); print(rel[0]["fileName"])')
  file_len=$(printf '%s' "$meta" | python3 -c 'import json,sys; files=json.load(sys.stdin)["data"]; rel=[f for f in files if f.get("releaseType")==1] or files; rel.sort(key=lambda f: f.get("dateCreated") or "", reverse=True); print(rel[0].get("fileLength") or 0)')
  hi=$((file_id / 1000)); lo=$((file_id % 1000))
  url="https://edge.forgecdn.net/files/${hi}/${lo}/${file_name}"
  if [[ -f "$file_name" ]]; then
    have=$(stat -c%s "$file_name" 2>/dev/null || echo 0)
    if [[ "$have" == "$file_len" && "$file_len" != "0" ]]; then
      echo "cached $file_name"
    else
      curl -L --fail --retry 3 -o "$file_name" "$url"
    fi
  else
    echo "Downloading $file_name"
    curl -L --fail --retry 3 -o "$file_name" "$url"
  fi
  PACK_ZIPS+=("$file_name")
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
