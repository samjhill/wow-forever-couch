#!/usr/bin/env bash
# Install Forever SelfBuffs (buff/debuff icon strip) + CouchBuffReminder (missing/expiring alerts).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

STAGING="${WOW_COUCH_CONFIG}/addons-staging"
mkdir -p "$STAGING" "$WOW_ADDONS"

# CurseForge project 1718593 — SelfBuffs Forever build (shared Python helper)
zip_path="$(python3 "${REPO_ROOT}/scripts/python/curseforge_fetch.py" --project 1718593 --staging "$STAGING")"
python3 "${REPO_ROOT}/scripts/python/unzip_addons.py" "$zip_path" --dest "$WOW_ADDONS"
echo "installed SelfBuffs → ${WOW_ADDONS}/SelfBuffs"

# Couch missing/expiring reminder
SRC="${REPO_ROOT}/addons/CouchBuffReminder"
DEST="${WOW_ADDONS}/CouchBuffReminder"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -a "${SRC}/." "$DEST/"
echo "installed CouchBuffReminder → $DEST"

WTF="${WOW_FOREVER}/WTF/Account"
if [[ -d "$WTF" ]]; then
  python3 "${REPO_ROOT}/scripts/python/enable_addons.py" --wtf-account "$WTF" \
    --enable SelfBuffs CouchBuffReminder --disable
fi

echo "Reload UI (/reload). SelfBuffs: /sb   Couch reminder: /cbr status"
