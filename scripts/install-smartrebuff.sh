#!/usr/bin/env bash
# Install Forever SmartRebuff (standard class/group buff monitor).
# Replaces SelfBuffs + CouchBuffReminder on the couch stack.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

STAGING="${WOW_COUCH_CONFIG}/addons-staging"
mkdir -p "$STAGING" "$WOW_ADDONS"

# CurseForge project 1728015 — SmartRebuff Forever buff monitor
zip_path="$(python3 "${REPO_ROOT}/scripts/python/curseforge_fetch.py" --project 1728015 --staging "$STAGING")"
python3 "${REPO_ROOT}/scripts/python/unzip_addons.py" "$zip_path" --dest "$WOW_ADDONS"
echo "installed SmartRebuff → ${WOW_ADDONS}/SmartRebuff"

# Drop previous custom buff stack if present
rm -rf "${WOW_ADDONS}/CouchBuffReminder" "${WOW_ADDONS}/SelfBuffs"

WTF="${WOW_FOREVER}/WTF/Account"
if [[ -d "$WTF" ]]; then
  python3 "${REPO_ROOT}/scripts/python/enable_addons.py" --wtf-account "$WTF" \
    --enable SmartRebuff \
    --disable SelfBuffs CouchBuffReminder
fi

echo "Reload UI (/reload). SmartRebuff: /smartrebuff or minimap button."
