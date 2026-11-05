#!/usr/bin/env bash
# Install Forever-tagged QoL addons (Baganator/Syndicator/Leatrix/Plater/Lore Forever/Fishing Log)
# and stage later-activation zips (Questie/BigWigs/GTFO/Talents Forever/Auctionator).
#
# Does NOT touch ConsolePort, Immersion, ForeverVO*, or CouchDictateRoute.
# Does NOT enable staged addons. Does NOT overwrite SavedVariables/profiles.
# Lore Forever: main zip includes male English narrator packs; do NOT install Quest Dialogue packs
# (ForeverVO owns quest/gossip speech; Lore's questDialogue defaults off).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

STAGING="${WOW_COUCH_CONFIG}/addons-staging"
STAGED_ZIPS="${STAGING}/staged"
DEST="${WOW_ADDONS}"
UA="wow-forever-couch-qol"
mkdir -p "$STAGING" "$STAGED_ZIPS" "$DEST"
cd "$STAGING"

# Set FETCHED_NAME to newest CurseForge release/beta listing game version 1.60.x.
# Optional 2nd arg: substring required in fileName (e.g. forever).
fetch_forever() {
  local project="$1"
  local name_filter="${2:-}"
  local meta file_id file_name file_len hi lo url have
  meta=$(curl -sL --fail \
    -H "Accept: application/json" -H "User-Agent: ${UA}" \
    "https://www.curseforge.com/api/v1/mods/${project}/files?pageSize=40&sortField=1&sortOrder=desc")
  read -r file_id file_name file_len < <(printf '%s' "$meta" | NAME_FILTER="$name_filter" python3 -c '
import json, sys, os
files = json.load(sys.stdin)["data"]
filt = os.environ.get("NAME_FILTER", "")

def ok(f):
    gvs = [str(v) for v in (f.get("gameVersions") or [])]
    if not any(v.startswith("1.60") for v in gvs):
        return False
    if f.get("releaseType") not in (1, 2):
        return False
    if filt and filt.lower() not in (f.get("fileName") or "").lower():
        return False
    return True

cand = [f for f in files if ok(f)]
# Prefer Release over Beta, then newest upload (dateCreated desc).
cand.sort(
    key=lambda f: (1 if f.get("releaseType") == 1 else 0, f.get("dateCreated") or ""),
    reverse=True,
)
if not cand:
    raise SystemExit("no Forever 1.60.x file")
f = cand[0]
print(f["id"], f["fileName"], f.get("fileLength") or 0)
')
  hi=$((file_id / 1000))
  lo=$((file_id % 1000))
  url="https://edge.forgecdn.net/files/${hi}/${lo}/${file_name}"
  if [[ -f "$file_name" ]]; then
    have=$(stat -c%s "$file_name" 2>/dev/null || stat -f%z "$file_name" 2>/dev/null || echo 0)
    if [[ "$have" == "$file_len" && "$file_len" != "0" ]]; then
      echo "cached $file_name"
    else
      echo "Downloading $file_name"
      curl -L --fail --retry 3 -A "$UA" -o "$file_name" "$url"
    fi
  else
    echo "Downloading $file_name"
    curl -L --fail --retry 3 -A "$UA" -o "$file_name" "$url"
  fi
  FETCHED_NAME="$file_name"
}

# Prefer Questie Forever build that includes the large DB (+v1.0) when available.
fetch_questie() {
  local meta file_id file_name file_len hi lo url have
  meta=$(curl -sL --fail \
    -H "Accept: application/json" -H "User-Agent: ${UA}" \
    "https://www.curseforge.com/api/v1/mods/334372/files?pageSize=40&sortField=1&sortOrder=desc")
  read -r file_id file_name file_len < <(printf '%s' "$meta" | python3 -c '
import json, sys
files = json.load(sys.stdin)["data"]

def ok(f):
    gvs = [str(v) for v in (f.get("gameVersions") or [])]
    return any(v.startswith("1.60") for v in gvs) and f.get("releaseType") in (1, 2)

cand = [f for f in files if ok(f)]
# Prefer DB bundles (+v1.0), then newest upload, then largest
cand.sort(
    key=lambda f: (
        "+v1.0" in (f.get("fileName") or ""),
        f.get("dateCreated") or "",
        f.get("fileLength") or 0,
    ),
    reverse=True,
)
if not cand:
    raise SystemExit("no Forever Questie file")
f = cand[0]
print(f["id"], f["fileName"], f.get("fileLength") or 0)
')
  hi=$((file_id / 1000))
  lo=$((file_id % 1000))
  url="https://edge.forgecdn.net/files/${hi}/${lo}/${file_name}"
  if [[ -f "$file_name" ]]; then
    have=$(stat -c%s "$file_name" 2>/dev/null || stat -f%z "$file_name" 2>/dev/null || echo 0)
    if [[ "$have" == "$file_len" && "$file_len" != "0" ]]; then
      echo "cached $file_name"
    else
      echo "Downloading $file_name"
      curl -L --fail --retry 3 -A "$UA" -o "$file_name" "$url"
    fi
  else
    echo "Downloading $file_name"
    curl -L --fail --retry 3 -A "$UA" -o "$file_name" "$url"
  fi
  FETCHED_NAME="$file_name"
}

is_preserved() {
  case "$1" in
    ConsolePort|ConsolePort_*|Immersion|ForeverVO|ForeverVO_Data_*|CouchDictateRoute) return 0 ;;
    *) return 1 ;;
  esac
}

unzip_addon_dirs() {
  local zip="$1"
  local target="$2"
  local tmp root d base toc
  tmp=$(mktemp -d)
  # Python zipfile handles Windows backslash paths that Info-ZIP warns about.
  python3 - "$zip" "$tmp" <<'PY'
import sys, zipfile
from pathlib import Path
zpath, dest = Path(sys.argv[1]), Path(sys.argv[2])
with zipfile.ZipFile(zpath) as zf:
    for info in zf.infolist():
        name = info.filename.replace("\\", "/")
        if not name or name.endswith("/"):
            (dest / name).mkdir(parents=True, exist_ok=True)
            continue
        out = dest / name
        out.parent.mkdir(parents=True, exist_ok=True)
        with zf.open(info) as src, open(out, "wb") as dst:
            dst.write(src.read())
PY
  root="$tmp"
  # If zip has a single non-addon wrapper dir, descend one level
  local entries=()
  while IFS= read -r -d '' e; do entries+=("$e"); done < <(find "$tmp" -mindepth 1 -maxdepth 1 -print0)
  if [[ ${#entries[@]} -eq 1 && -d "${entries[0]}" ]]; then
    if ! ls "${entries[0]}"/*.toc >/dev/null 2>&1; then
      # wrapper containing addon folders
      if ls "${entries[0]}"/*/*.toc >/dev/null 2>&1 || ls "${entries[0]}"/*/. >/dev/null 2>&1; then
        root="${entries[0]}"
      fi
    fi
  fi
  for d in "$root"/*/; do
    [[ -d "$d" ]] || continue
    base=$(basename "$d")
    if is_preserved "$base"; then
      echo "skip preserved $base"
      continue
    fi
    if ! ls "$d"*.toc >/dev/null 2>&1 && ! ls "$d"/*.toc >/dev/null 2>&1; then
      # might still be an addon folder with nested toc
      if ! find "$d" -maxdepth 2 -name '*.toc' | head -1 | grep -q .; then
        continue
      fi
    fi
    rm -rf "${target}/${base}"
    mkdir -p "${target}/${base}"
    cp -a "${d}." "${target}/${base}/"
    echo "installed $base"
  done
  if ls "$root"/*.toc >/dev/null 2>&1; then
    toc=$(ls "$root"/*.toc | head -1)
    base=$(basename "$toc" .toc)
    if ! is_preserved "$base"; then
      rm -rf "${target}/${base}"
      mkdir -p "${target}/${base}"
      cp -a "${root}/." "${target}/${base}/"
      echo "installed $base (flat)"
    fi
  fi
  rm -rf "$tmp"
}

echo "=== download install set ==="
fetch_forever 988370
SYN_ZIP="$FETCHED_NAME"
fetch_forever 914482
BAG_ZIP="$FETCHED_NAME"
fetch_forever 94855 forever
LEA_ZIP="$FETCHED_NAME"
fetch_forever 100547
PLA_ZIP="$FETCHED_NAME"
# Lore Forever (large zip; includes LoreForever + Default/Alliance/Horde narrator packs)
fetch_forever 1715510
LORE_ZIP="$FETCHED_NAME"
# The Fishing Log (Forever fishing tracker / matches)
fetch_forever 1702832
FISH_ZIP="$FETCHED_NAME"
# Forever Loot Sparkles — quest-item sparkles (+ optional herb/ore)
fetch_forever 1729017
SPARKLE_ZIP="$FETCHED_NAME"
# NodeSight — live herb/ore icons on minimap tracking dots (controller-friendly)
fetch_forever 1731463
NODESIGHT_ZIP="$FETCHED_NAME"
# Gather Radar — live icons + remembered herb/ore pins on minimap & world map
fetch_forever 1757790
GATHER_ZIP="$FETCHED_NAME"

echo "=== install into AddOns (preserve couch stack) ==="
for z in "$SYN_ZIP" "$BAG_ZIP" "$LEA_ZIP" "$PLA_ZIP" "$LORE_ZIP" "$FISH_ZIP" "$SPARKLE_ZIP" "$NODESIGHT_ZIP" "$GATHER_ZIP"; do
  unzip_addon_dirs "$z" "$DEST"
done
# Immersion already covers controller quest/gossip; do not install DialogKey forks.
rm -rf "${DEST}/DialogKey_Numy" "${DEST}/DialogKey_Aeonzara" "${DEST}/DialogKey"

echo "=== stage later-activation zips (not enabled) ==="
fetch_questie
QUESTIE_ZIP="$FETCHED_NAME"
fetch_forever 2382
BW_ZIP="$FETCHED_NAME"
fetch_forever 20697
GTFO_ZIP="$FETCHED_NAME"
fetch_forever 1700435
TF_ZIP="$FETCHED_NAME"
fetch_forever 6124
AUC_ZIP="$FETCHED_NAME"

for z in "$QUESTIE_ZIP" "$BW_ZIP" "$GTFO_ZIP" "$TF_ZIP" "$AUC_ZIP"; do
  [[ -f "$z" ]] || { echo "missing stage zip $z" >&2; exit 2; }
  cp -f "$z" "$STAGED_ZIPS/"
  echo "staged $z → $STAGED_ZIPS/"
done

{
  echo "# Forever QoL addon manifest $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "addons_dir=$DEST"
  echo
  echo "## installed (enable via enable-forever-addons.sh)"
  echo "- $SYN_ZIP"
  echo "- $BAG_ZIP"
  echo "- $LEA_ZIP"
  echo "- $PLA_ZIP"
  echo "- $LORE_ZIP"
  echo "- $FISH_ZIP"
  echo "- $SPARKLE_ZIP"
  echo "- $NODESIGHT_ZIP"
  echo "- $GATHER_ZIP"
  echo
  echo "## staged zips (NOT in AddOns / not enabled)"
  echo "- $QUESTIE_ZIP"
  echo "- $BW_ZIP"
  echo "- $GTFO_ZIP"
  echo "- $TF_ZIP"
  echo "- $AUC_ZIP"
} | tee "$STAGED_ZIPS/MANIFEST.txt"

echo "=== AddOns now ==="
ls -1 "$DEST"
echo "Done. Run scripts/enable-forever-addons.sh to enable the install set."
echo "Staged zips live in $STAGED_ZIPS (do not enable until launch-day activation)."
