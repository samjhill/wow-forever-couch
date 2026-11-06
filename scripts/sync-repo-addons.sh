#!/usr/bin/env bash
# Copy/update repo-owned Forever addons into Interface/AddOns (idempotent).
# Does not touch CurseForge downloads or SavedVariables.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if [[ ! -d "$WOW_ADDONS" ]]; then
  echo "Forever AddOns dir missing: $WOW_ADDONS" >&2
  echo "Install Forever and launch once, then re-run." >&2
  exit 2
fi

install_local() {
  local name="$1"
  local src="${REPO_ROOT}/addons/${name}"
  local dest="${WOW_ADDONS}/${name}"
  if [[ ! -d "$src" ]]; then
    echo "skip missing repo addon: $name"
    return 0
  fi
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -a "${src}/." "$dest/"
  echo "synced $name → $dest"
}

install_local ConsolePortCouch
install_local CouchDictateRoute
install_local PlaterQuestPin
rm -rf "${WOW_ADDONS}/CouchBuffReminder" "${WOW_ADDONS}/SelfBuffs"

# Prefer dedicated installers when present (enable AddOns.txt, SmartRebuff zip, etc.)
if [[ -x "${REPO_ROOT}/scripts/install-consoleport-couch.sh" ]]; then
  "${REPO_ROOT}/scripts/install-consoleport-couch.sh" || true
fi
if [[ -x "${REPO_ROOT}/scripts/install-couch-dictate-route.sh" ]]; then
  "${REPO_ROOT}/scripts/install-couch-dictate-route.sh" || true
fi
if [[ -x "${REPO_ROOT}/scripts/install-plater-quest-pin.sh" ]] && [[ -d "${WOW_ADDONS}/Plater" ]]; then
  "${REPO_ROOT}/scripts/install-plater-quest-pin.sh" || true
fi
if [[ -x "${REPO_ROOT}/scripts/install-smartrebuff.sh" ]]; then
  "${REPO_ROOT}/scripts/install-smartrebuff.sh" || true
fi

if [[ -x "${REPO_ROOT}/scripts/enable-forever-addons.sh" ]] && [[ -d "${WOW_FOREVER}/WTF/Account" ]]; then
  "${REPO_ROOT}/scripts/enable-forever-addons.sh" || true
fi

echo "Repo addon sync done."
