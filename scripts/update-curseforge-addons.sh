#!/usr/bin/env bash
# Refresh Forever CurseForge addons (1.60.x files only).
# Skips when Forever is running. Safe to run from the launch hook and the 6h timer.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

LOCK_DIR="${XDG_RUNTIME_DIR:-/tmp}"
LOCK_FILE="${LOCK_DIR}/wow-curseforge-addons.lock"
mkdir -p "$LOCK_DIR"
exec 8>"$LOCK_FILE"
if command -v flock >/dev/null 2>&1; then
  if ! flock -n 8; then
    echo "CurseForge addon update already running — skip"
    exit 0
  fi
fi

if pgrep -f 'Wow\.exe|WowForever|WowClassic' >/dev/null 2>&1; then
  echo "Forever is running — skip CurseForge addon update"
  exit 0
fi

if [[ ! -d "$WOW_ADDONS" ]]; then
  echo "Forever AddOns dir missing: $WOW_ADDONS" >&2
  exit 2
fi

STAGING="${WOW_COUCH_CONFIG}/addons-staging"
mkdir -p "$STAGING"
WTF="${WOW_FOREVER}/WTF/Account"
args=(
  python3 "${REPO_ROOT}/scripts/python/update_curseforge_addons.py"
  --addons "$WOW_ADDONS"
  --staging "$STAGING"
)
if [[ -d "$WTF" ]]; then
  args+=(--wtf-account "$WTF")
fi
exec "${args[@]}"
