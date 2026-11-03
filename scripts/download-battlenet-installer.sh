#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
OUT="${HOME}/Downloads/Battle.net-Setup.exe"
URL="https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe"
mkdir -p "${HOME}/Downloads"
if [[ -f "$OUT" && -s "$OUT" ]]; then
  echo "Already present: $OUT ($(du -h "$OUT" | cut -f1))"
  exit 0
fi
echo "Downloading official Battle.net installer..."
curl -L --fail --retry 3 -o "$OUT.partial" "$URL"
mv "$OUT.partial" "$OUT"
echo "Saved $OUT ($(du -h "$OUT" | cut -f1))"
