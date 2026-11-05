#!/usr/bin/env bash
# Install PlaterQuestPin (forces quest-mob tracking/color on Forever nameplates).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

SRC="${REPO_ROOT}/addons/PlaterQuestPin"
DEST="${WOW_ADDONS}/PlaterQuestPin"

if [[ ! -f "${SRC}/PlaterQuestPin.toc" ]]; then
  echo "missing addon source: $SRC" >&2
  exit 2
fi
if [[ ! -d "${WOW_ADDONS}/Plater" ]]; then
  echo "Plater not installed." >&2
  exit 2
fi

mkdir -p "$WOW_ADDONS"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -a "${SRC}/." "$DEST/"
echo "installed → $DEST"

WTF="${WOW_FOREVER}/WTF/Account"
if [[ -d "$WTF" ]]; then
  python3 - "$WTF" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
for f in list(root.glob("*/AddOns.txt")) + list(root.glob("*/*/AddOns.txt")) + list(root.glob("*/*/*/AddOns.txt")):
    if "SavedVariables" in str(f):
        continue
    lines = f.read_text(encoding="utf-8", errors="replace").splitlines()
    found = False
    out = []
    for line in lines:
        if line.startswith("PlaterQuestPin:"):
            out.append("PlaterQuestPin: enabled")
            found = True
        else:
            out.append(line)
    if not found:
        out.append("PlaterQuestPin: enabled")
    f.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"enabled in {f}")
PY
fi

# Best-effort pin CVar into config caches (client must /reload or relaunch to load addon).
python3 - <<'PY'
from pathlib import Path
import re
root = Path.home() / "Games/battlenet/pfx/drive_c/Program Files (x86)/World of Warcraft/_forever_/WTF"
if not root.exists():
    raise SystemExit(0)
for path in root.rglob("config-cache.wtf"):
    text = path.read_text(encoding="utf-8", errors="replace")
    line = 'SET showQuestTrackingTooltips "1"'
    pat = re.compile(r'(?im)^SET\s+showQuestTrackingTooltips\s+.*$')
    if pat.search(text):
        text = pat.sub(line, text, count=1)
    else:
        if text and not text.endswith("\n"):
            text += "\n"
        text += line + "\n"
    path.write_text(text, encoding="utf-8")
    print(f"pinned CVar in {path}")
PY

echo "Reload UI (/reload) or run /platerquestpin. Quest mobs should tint; tooltip shows N/M kill progress."
