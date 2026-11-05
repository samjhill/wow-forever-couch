#!/usr/bin/env bash
# Install Forever SelfBuffs (buff/debuff icon strip) + CouchBuffReminder (missing/expiring alerts).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

STAGING="${WOW_COUCH_CONFIG}/addons-staging"
UA="wow-forever-couch"
mkdir -p "$STAGING" "$WOW_ADDONS"
cd "$STAGING"

# CurseForge project 1718593 — SelfBuffs Forever build
meta=$(curl -sL --fail -H "Accept: application/json" -H "User-Agent: ${UA}" \
  "https://www.curseforge.com/api/v1/mods/1718593/files?pageSize=20&sortField=1&sortOrder=desc")
read -r file_id file_name file_len < <(printf '%s' "$meta" | python3 -c '
import json, sys
files = json.load(sys.stdin)["data"]
cand = [f for f in files
        if any(str(v).startswith("1.60") for v in (f.get("gameVersions") or []))
        and f.get("releaseType") in (1, 2)]
cand.sort(key=lambda f: (1 if f.get("releaseType") == 1 else 0, f.get("dateCreated") or ""), reverse=True)
if not cand:
    raise SystemExit("no Forever SelfBuffs file")
f = cand[0]
print(f["id"], f["fileName"], f.get("fileLength") or 0)
')
hi=$((file_id / 1000))
lo=$((file_id % 1000))
url="https://edge.forgecdn.net/files/${hi}/${lo}/${file_name}"
if [[ -f "$file_name" ]]; then
  have=$(stat -c%s "$file_name" 2>/dev/null || stat -f%z "$file_name" 2>/dev/null || echo 0)
  if [[ "$have" != "$file_len" || "$file_len" == "0" ]]; then
    curl -L --fail --retry 3 -A "$UA" -o "$file_name" "$url"
  else
    echo "cached $file_name"
  fi
else
  echo "Downloading $file_name"
  curl -L --fail --retry 3 -A "$UA" -o "$file_name" "$url"
fi

tmp=$(mktemp -d)
python3 - "$file_name" "$tmp" <<'PY'
import sys, zipfile
from pathlib import Path
zpath, dest = Path(sys.argv[1]), Path(sys.argv[2])
with zipfile.ZipFile(zpath) as zf:
    for info in zf.infolist():
        name = info.filename.replace("\\", "/")
        if not name or name.endswith("/"):
            (dest / name).mkdir(parents=True, exist_ok=True)
            continue
        out = dest / name
        out.parent.mkdir(parents=True, exist_ok=True)
        with zf.open(info) as src, open(out, "wb") as dst:
            dst.write(src.read())
PY
# Find SelfBuffs folder
src=""
if [[ -f "$tmp/SelfBuffs/SelfBuffs.toc" ]]; then
  src="$tmp/SelfBuffs"
elif [[ -f "$tmp/SelfBuffs.toc" ]]; then
  src="$tmp"
else
  src=$(find "$tmp" -name 'SelfBuffs.toc' | head -1 | xargs dirname)
fi
[[ -n "$src" && -f "$src/SelfBuffs.toc" ]] || { echo "SelfBuffs.toc not found in zip" >&2; exit 2; }
rm -rf "${WOW_ADDONS}/SelfBuffs"
mkdir -p "${WOW_ADDONS}/SelfBuffs"
cp -a "${src}/." "${WOW_ADDONS}/SelfBuffs/"
echo "installed SelfBuffs → ${WOW_ADDONS}/SelfBuffs"
rm -rf "$tmp"

# Couch missing/expiring reminder
SRC="${REPO_ROOT}/addons/CouchBuffReminder"
DEST="${WOW_ADDONS}/CouchBuffReminder"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -a "${SRC}/." "$DEST/"
echo "installed CouchBuffReminder → $DEST"

WTF="${WOW_FOREVER}/WTF/Account"
if [[ -d "$WTF" ]]; then
  python3 - "$WTF" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
for name in ("SelfBuffs", "CouchBuffReminder"):
    for f in list(root.glob("*/AddOns.txt")) + list(root.glob("*/*/AddOns.txt")) + list(root.glob("*/*/*/AddOns.txt")):
        if "SavedVariables" in str(f):
            continue
        lines = f.read_text(encoding="utf-8", errors="replace").splitlines()
        found = False
        out = []
        for line in lines:
            if line.startswith(f"{name}:"):
                out.append(f"{name}: enabled")
                found = True
            else:
                out.append(line)
        if not found:
            out.append(f"{name}: enabled")
        f.write_text("\n".join(out) + "\n", encoding="utf-8")
        print(f"enabled {name} in {f}")
PY
fi

echo "Reload UI (/reload). SelfBuffs: /sb   Couch reminder: /cbr status"
