#!/usr/bin/env bash
# Install Forever-tagged QoL addons (Leatrix/Plater/Lore Forever/Fishing Log/Questie)
# and stage later-activation zips (BigWigs/GTFO/Talents Forever/Auctionator).
#
# Does NOT touch Immersion, Spoken*, or CouchDictateRoute.
# Does NOT enable staged addons. Does NOT overwrite SavedVariables/profiles.
# Lore Forever: main zip includes male English narrator packs; do NOT install Quest Dialogue packs
# (Spoken owns quest/gossip speech; Lore's questDialogue defaults off).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

STAGING="${WOW_COUCH_CONFIG}/addons-staging"
STAGED_ZIPS="${STAGING}/staged"
DEST="${WOW_ADDONS}"
mkdir -p "$STAGING" "$STAGED_ZIPS" "$DEST"
cd "$STAGING"

# Set FETCHED_NAME to newest CurseForge release/beta listing game version 1.60.x.
# Optional 2nd arg: substring required in fileName (e.g. forever).
# Shared with Windows via scripts/python/curseforge_fetch.py
fetch_forever() {
  local project="$1"
  local name_filter="${2:-}"
  local path args=(python3 "${REPO_ROOT}/scripts/python/curseforge_fetch.py" --project "$project" --staging "$STAGING")
  [[ -n "$name_filter" ]] && args+=(--name-filter "$name_filter")
  path="$("${args[@]}")"
  FETCHED_NAME="$(basename "$path")"
}

is_preserved() {
  case "$1" in
    Immersion|Spoken|Spoken_*|SpokenContributions|SpokenQuestsAudio*|SpokenPlacesAudio|SpokenReadablesAudio|SpokenBossesAudio|CouchDictateRoute) return 0 ;;
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
# AutoFeed — self-updating AutoFeed (eat) + AutoDrink macros
fetch_forever 1703450
AUTOFEED_ZIP="$FETCHED_NAME"
# SmartRebuff — Forever class/group buff monitor (replaces SelfBuffs + CouchBuffReminder)
fetch_forever 1728015
SMARTREBUFF_ZIP="$FETCHED_NAME"
# Questie addon and its separate Forever database (objective locations live in QuestieDB).
fetch_forever 334372
QUESTIE_ZIP="$FETCHED_NAME"
fetch_forever 1696795 forever
QUESTIEDB_ZIP="$FETCHED_NAME"

echo "=== install into AddOns (preserve couch stack) ==="
for z in "$LEA_ZIP" "$PLA_ZIP" "$LORE_ZIP" "$FISH_ZIP" "$SPARKLE_ZIP" "$NODESIGHT_ZIP" "$AUTOFEED_ZIP" "$SMARTREBUFF_ZIP" "$QUESTIE_ZIP" "$QUESTIEDB_ZIP"; do
  unzip_addon_dirs "$z" "$DEST"
done
# Built-in bags replace Baganator; Syndicator only indexed inventory for it.
rm -rf "${DEST}/Baganator" "${DEST}/Syndicator"
rm -rf "${DEST}/GatherRadar"
# Drop previous custom buff stack
rm -rf "${DEST}/CouchBuffReminder" "${DEST}/SelfBuffs"
# Immersion already covers controller quest/gossip; do not install DialogKey forks.
rm -rf "${DEST}/DialogKey_Numy" "${DEST}/DialogKey_Aeonzara" "${DEST}/DialogKey"

echo "=== stage later-activation zips (not enabled) ==="
fetch_forever 2382
BW_ZIP="$FETCHED_NAME"
fetch_forever 20697
GTFO_ZIP="$FETCHED_NAME"
fetch_forever 1700435
TF_ZIP="$FETCHED_NAME"
fetch_forever 6124
AUC_ZIP="$FETCHED_NAME"

for z in "$BW_ZIP" "$GTFO_ZIP" "$TF_ZIP" "$AUC_ZIP"; do
  [[ -f "$z" ]] || { echo "missing stage zip $z" >&2; exit 2; }
  cp -f "$z" "$STAGED_ZIPS/"
  echo "staged $z → $STAGED_ZIPS/"
done

{
  echo "# Forever QoL addon manifest $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "addons_dir=$DEST"
  echo
  echo "## installed (enable via enable-forever-addons.sh)"
  echo "- $LEA_ZIP"
  echo "- $PLA_ZIP"
  echo "- $LORE_ZIP"
  echo "- $FISH_ZIP"
  echo "- $SPARKLE_ZIP"
  echo "- $NODESIGHT_ZIP"
  echo "- $AUTOFEED_ZIP"
  echo "- $SMARTREBUFF_ZIP"
  echo "- $QUESTIE_ZIP"
  echo "- $QUESTIEDB_ZIP"
  echo
  echo "## staged zips (NOT in AddOns / not enabled)"
  echo "- $BW_ZIP"
  echo "- $GTFO_ZIP"
  echo "- $TF_ZIP"
  echo "- $AUC_ZIP"
} | tee "$STAGED_ZIPS/MANIFEST.txt"

echo "=== AddOns now ==="
ls -1 "$DEST"
echo "Done. Run scripts/enable-forever-addons.sh to enable the install set."
echo "Staged zips live in $STAGED_ZIPS (do not enable until launch-day activation)."
