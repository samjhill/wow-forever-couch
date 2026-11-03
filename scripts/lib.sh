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

mkdir -p "$WOW_COUCH_CONFIG"
