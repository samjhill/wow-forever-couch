#!/usr/bin/env bash
# Install ConsolePortCouch (applies Xbox recommended bindings for Steam Input).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

SRC="${REPO_ROOT}/addons/ConsolePortCouch"
DEST="${WOW_ADDONS}/ConsolePortCouch"

if [[ ! -f "${SRC}/ConsolePortCouch.toc" ]]; then
  echo "missing addon source: $SRC" >&2
  exit 2
fi
if [[ ! -d "${WOW_ADDONS}/ConsolePort" ]]; then
  echo "ConsolePort not installed. Run scripts/install-forever-addons.sh first." >&2
  exit 2
fi

mkdir -p "$WOW_ADDONS"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -a "${SRC}/." "$DEST/"
echo "installed → $DEST"

# Best-effort enable (Forever Name: enabled format via enable script if present)
if [[ -x "${REPO_ROOT}/scripts/enable-forever-addons.sh" ]]; then
  # Temporarily ensure ConsolePortCouch is in the enable list by writing char/account files
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
        if line.startswith("ConsolePortCouch:"):
            out.append("ConsolePortCouch: enabled")
            found = True
        else:
            out.append(line)
    if not found:
        out.append("ConsolePortCouch: enabled")
    f.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"enabled in {f}")
PY
  fi
fi

echo "Reload UI (/reload). Chat should show: ConsolePort Couch: applied Xbox recommended bindings."
echo "Force again anytime: /cpcouch apply"
