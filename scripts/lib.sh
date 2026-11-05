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
