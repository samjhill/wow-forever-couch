#!/usr/bin/env bash
# Shared paths for wow-forever-couch. Source from other scripts:
#   # shellcheck source=lib.sh
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT
export WOW_COUCH_CONFIG="${WOW_COUCH_CONFIG:-$REPO_ROOT/config}"
export WOW_PREFIX="${WOW_PREFIX:-$HOME/Games/battlenet}"
export WOW_FOREVER="${WOW_FOREVER:-$WOW_PREFIX/pfx/drive_c/Program Files (x86)/World of Warcraft/_forever_}"
export WOW_ADDONS="${WOW_ADDONS:-$WOW_FOREVER/Interface/AddOns}"
export WOW_COMPAT_TOOL="${WOW_COMPAT_TOOL:-$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton11-12}"
export STEAM_COMPAT_TOOLS_DIR="${STEAM_COMPAT_TOOLS_DIR:-$HOME/.local/share/Steam/compatibilitytools.d}"

# Resolve GE-Proton binary: prefer WOW_COMPAT_TOOL when present, else newest GE-Proton*/proton.
resolve_ge_proton() {
  local preferred="${WOW_COMPAT_TOOL}/proton"
  if [[ -x "$preferred" ]]; then
    printf '%s' "$preferred"
    return
  fi
  local newest=""
  local candidate
  # shellcheck disable=SC2012
  for candidate in $(ls -1d "${STEAM_COMPAT_TOOLS_DIR}"/GE-Proton*/proton 2>/dev/null | sort -V); do
    if [[ -x "$candidate" ]]; then
      newest="$candidate"
    fi
  done
  if [[ -n "$newest" ]]; then
    printf '%s' "$newest"
    return
  fi
  printf ''
}

export WOW_PROTON="$(resolve_ge_proton)"
if [[ -n "$WOW_PROTON" ]]; then
  export WOW_COMPAT_TOOL="$(cd "$(dirname "$WOW_PROTON")" && pwd)"
fi

# Setup drops Battle.net.exe under .battle.net/.extract before it writes
# .product.db and Launcher.db. Launching that copy shows
# "required application data could not be found".
battlenet_app_ready() {
  local root="${WOW_PREFIX}/pfx/drive_c/Program Files (x86)/Battle.net"
  [[ -s "${root}/.product.db" && -f "${root}/Launcher.db" ]]
}

find_battlenet_exe() {
  battlenet_app_ready || return 0
  local root="${WOW_PREFIX}/pfx/drive_c/Program Files (x86)/Battle.net"
  local default_exe="${root}/Battle.net.exe"
  local extract_exe="${root}/.battle.net/.extract/Battle.net.exe"
  if [[ -f "$default_exe" ]]; then
    printf '%s' "$default_exe"
    return
  fi
  if [[ -f "$extract_exe" ]]; then
    printf '%s' "$extract_exe"
    return
  fi
}

forever_client_ready() {
  [[ -f "${WOW_FOREVER}/Wow.exe" ]] \
    || [[ -f "${WOW_FOREVER}/WowClassic.exe" ]] \
    || [[ -f "${WOW_FOREVER}/WowForever.exe" ]] \
    || [[ -d "${WOW_FOREVER}/Interface/AddOns" ]]
}

# Host profile: explicit WOW_COUCH_PROFILE wins; else auto-detect Steam Deck.
detect_couch_profile() {
  if [[ -n "${WOW_COUCH_PROFILE:-}" ]]; then
    printf '%s' "$WOW_COUCH_PROFILE"
    return
  fi
  local product=""
  if [[ -r /sys/devices/virtual/dmi/id/product_name ]]; then
    product="$(tr -d '\0' </sys/devices/virtual/dmi/id/product_name 2>/dev/null || true)"
  fi
  case "${product}" in
    *Jupiter*|*Galileo*|*SteamDeck*)
      printf 'deck'
      return
      ;;
  esac
  if [[ -f /etc/os-release ]] && grep -qiE 'steamos|steam deck' /etc/os-release 2>/dev/null; then
    printf 'deck'
    return
  fi
  if [[ -f /etc/os-release ]] && grep -qi 'bazzite' /etc/os-release 2>/dev/null; then
    # Living-room boxes are often NVIDIA; callers may still export deck/bazzite-nvidia.
    printf 'bazzite-nvidia'
    return
  fi
  printf 'default'
}

export WOW_COUCH_PROFILE="$(detect_couch_profile)"
_PROFILE_FILE="${REPO_ROOT}/profiles/${WOW_COUCH_PROFILE}.env"
if [[ -f "$_PROFILE_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$_PROFILE_FILE"
fi
unset _PROFILE_FILE

mkdir -p "$WOW_COUCH_CONFIG"
