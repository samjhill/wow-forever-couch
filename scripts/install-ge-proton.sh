#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
API="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "Resolving latest GE-Proton release..."
TAG=$(curl -fsSL "$API" | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
echo "Latest tag: $TAG"
# Prefer x86_64 asset name used by recent GE-Proton releases
ASSET="${TAG}-x86_64.tar.gz"
URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${TAG}/${ASSET}"
LUTRIS_DIR="${HOME}/.local/share/lutris/runners/wine"
STEAM_DIR="${HOME}/.local/share/Steam/compatibilitytools.d"
mkdir -p "$LUTRIS_DIR" "$STEAM_DIR"
if [[ -d "${STEAM_DIR}/${TAG}" || -d "${LUTRIS_DIR}/${TAG}" ]]; then
  echo "Already installed: $TAG"
  exit 0
fi
# Also match extracted folder that may include arch suffix stripped
if compgen -G "${STEAM_DIR}/GE-Proton*" > /dev/null; then
  if [[ -d "${STEAM_DIR}/${TAG}" ]]; then
    echo "Already installed under Steam tools."
    exit 0
  fi
fi
echo "Downloading $URL ..."
curl -L --fail --retry 3 -o "$TMP/$ASSET" "$URL"
echo "Extracting..."
tar -xzf "$TMP/$ASSET" -C "$TMP"
DIRNAME=$(find "$TMP" -maxdepth 1 -type d \( -name 'GE-Proton*' -o -name "${TAG}*" \) ! -path "$TMP" | head -1)
basename_dir=$(basename "$DIRNAME")
# Normalize destination name to tag for Lutris visibility
cp -a "$DIRNAME" "$STEAM_DIR/$TAG"
cp -a "$DIRNAME" "$LUTRIS_DIR/$TAG"
echo "Installed to:"
echo "  $STEAM_DIR/$TAG"
echo "  $LUTRIS_DIR/$TAG"
echo "Select this runner in Lutris → Battle.net → Runner options."
