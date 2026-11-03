#!/usr/bin/env bash
# Install CouchDictateRoute into Forever Interface/AddOns and enable it.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

SRC="${REPO_ROOT}/addons/CouchDictateRoute"
DEST="${WOW_ADDONS}/CouchDictateRoute"

if [[ ! -f "${SRC}/CouchDictateRoute.toc" ]]; then
  echo "missing addon source: $SRC" >&2
  exit 2
fi

mkdir -p "$WOW_ADDONS"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -a "${SRC}/." "$DEST/"
echo "installed → $DEST"

# Best-effort enable in existing AddOns.txt files
WTF="${WOW_FOREVER}/WTF/Account"
if [[ -d "$WTF" ]]; then
  shopt -s nullglob
  for f in "$WTF"/*/AddOns.txt "$WTF"/*/*/AddOns.txt; do
    if ! grep -qx "enable CouchDictateRoute" "$f" 2>/dev/null; then
      echo "enable CouchDictateRoute" >> "$f"
      echo "enabled in $f"
    fi
  done
else
  echo "No WTF/Account yet — enable CouchDictateRoute at character select after first login."
fi

echo "Reload UI (/reload) or relog. Check with /cdr status"
