#!/usr/bin/env bash
# Pin Forever Config.wtf for stable Proton + NVIDIA (DX11, vsync, FPS cap).
# Safe to re-run. Quality tier is pinned once unless FOREVER_GRAPHICS_FORCE=1.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

CFG="${WOW_FOREVER}/WTF/Config.wtf"
FLAG="${WOW_COUCH_CONFIG}/forever-graphics-pinned"

if [[ ! -d "$WOW_FOREVER" ]]; then
  echo "Forever client missing: $WOW_FOREVER" >&2
  exit 2
fi
mkdir -p "$(dirname "$CFG")" "$WOW_COUCH_CONFIG"
touch "$CFG"

pin_set() {
  local key="$1"
  local val="$2"
  python3 - "$CFG" "$key" "$val" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
key, val = sys.argv[2], sys.argv[3]
text = path.read_text(encoding="utf-8", errors="replace")
pat = re.compile(rf'(?im)^SET\s+{re.escape(key)}\s+".*"\s*$')
line = f'SET {key} "{val}"'
if pat.search(text):
    text = pat.sub(line, text, count=1)
else:
    if text and not text.endswith("\n"):
        text += "\n"
    text += line + "\n"
path.write_text(text, encoding="utf-8")
print(f"pinned {key}={val}")
PY
}

# Always re-apply API / pacing (game can flip these after a crash or GPU detect).
pin_set GxApi D3D11
pin_set vsync 1
pin_set maxFPS 60

# Gamepad: stop Menu/Start (Escape) from only flipping crosshair ↔ free mouse cursor.
# ConsolePortCouch also pins these at login and binds PADFORWARD/PADSYSTEM → TOGGLEGAMEMENU.
pin_set GamePadCursorAutoEnable 0
pin_set GamePadCursorCenteredEmulation 0
pin_set GamePadCursorLeftClick none
pin_set GamePadCursorRightClick none

# Soften defaults once — couch box is CPU-limited (4c/4t); raise in-game if desired.
if [[ "${FOREVER_GRAPHICS_FORCE:-0}" == "1" || ! -f "$FLAG" ]]; then
  pin_set graphicsQuality 3
  pin_set RAIDgraphicsQuality 3
  date -u +%Y-%m-%dT%H:%M:%SZ > "$FLAG"
  echo "pinned quality tier 3 (once; delete $FLAG or FORCE=1 to re-apply)"
else
  echo "quality tier already pinned ($FLAG); skipping graphicsQuality"
fi

echo "Done. Fully quit Forever/Battle.net and relaunch for Config.wtf to load."
echo "Prefer Gaming Mode for play: steamos-session-select gamescope"
