#!/usr/bin/env bash
# Snapshot the live Forever couch setup into config/live-setup/ (safe to commit).
# Run on the Bazzite box (or any host with WOW_FOREVER). Prefer Forever fully quit
# so SavedVariables match what you just played.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DEST="${WOW_COUCH_CONFIG}/live-setup"
STAMP=$(date -u +%Y-%m-%dT%H:%MZ)
WTF="${WOW_FOREVER}/WTF"
ACCT_ROOT="${WTF}/Account"

if [[ ! -d "$ACCT_ROOT" ]]; then
  echo "No WTF/Account under $WOW_FOREVER" >&2
  exit 2
fi

# Pick the first non-SavedVariables account folder (live couch uses one).
ACCT=""
for d in "$ACCT_ROOT"/*/; do
  base=$(basename "$d")
  [[ "$base" == "SavedVariables" ]] && continue
  ACCT="$d"
  break
done
if [[ -z "$ACCT" || ! -d "$ACCT" ]]; then
  echo "No account folder found under $ACCT_ROOT" >&2
  exit 2
fi
ACCT_NAME=$(basename "${ACCT%/}")

# Character path: first realm/char that has AddOns.txt
CHAR_REL=""
CHAR_DIR=""
shopt -s nullglob
for f in "$ACCT"/*/*/AddOns.txt; do
  CHAR_DIR=$(dirname "$f")
  # relative to Account/<name>/
  CHAR_REL="${CHAR_DIR#"$ACCT"}"
  CHAR_REL="${CHAR_REL#/}"
  break
done

rm -rf "$DEST"
mkdir -p \
  "$DEST/account" \
  "$DEST/account/SavedVariables" \
  "$DEST/character/SavedVariables" \
  "$DEST/wtf"

ACCOUNT_SV=(
  ConsolePort.lua ConsolePort_Bar.lua ConsolePort_Cursor.lua ConsolePort_Rings.lua
  ConsolePortCouch.lua Immersion.lua ForeverVO.lua CouchDictateRoute.lua
  Leatrix_Plus.lua Baganator.lua Syndicator.lua Plater.lua LoreForever.lua TheFishingLog.lua
)
CHAR_SV=(
  ConsolePort.lua ConsolePort_Bar.lua ConsolePort_Rings.lua ConsolePort_Target.lua
  Baganator.lua ForeverVO.lua Plater.lua TheFishingLog.lua
)

copy_if() {
  local src="$1" dst="$2"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    echo "  + ${dst#"$DEST/"}"
  fi
}

echo "Snapshot → $DEST"
echo "  account=$ACCT_NAME character=${CHAR_REL:-none} stamp=$STAMP"

copy_if "$ACCT/AddOns.txt" "$DEST/account/AddOns.txt"
copy_if "$ACCT/bindings-cache.wtf" "$DEST/account/bindings-cache.wtf"
for name in "${ACCOUNT_SV[@]}"; do
  copy_if "$ACCT/SavedVariables/$name" "$DEST/account/SavedVariables/$name"
done

if [[ -n "$CHAR_DIR" ]]; then
  copy_if "$CHAR_DIR/AddOns.txt" "$DEST/character/AddOns.txt"
  for name in "${CHAR_SV[@]}"; do
    copy_if "$CHAR_DIR/SavedVariables/$name" "$DEST/character/SavedVariables/$name"
  done
fi

# Graphics / pad config (no secrets in typical Forever Config.wtf)
copy_if "$WTF/Config.wtf" "$DEST/wtf/Config.wtf"
copy_if "$WTF/gamecontrollerdb.txt" "$DEST/wtf/gamecontrollerdb.txt"
copy_if "$WTF/GamePadConfig_Addons.json" "$DEST/wtf/GamePadConfig_Addons.json"
copy_if "$WTF/GamePadConfig_Default.json" "$DEST/wtf/GamePadConfig_Default.json"

# Drop ForeverVO capture tables; keep showPanel off (Immersion owns quest UI).
python3 - "$DEST" <<'PY'
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
for path in root.rglob("ForeverVO.lua"):
    text = path.read_text(encoding="utf-8", errors="replace")
    orig = text
    text = re.sub(
        r"\nForeverVOCaptureDB\s*=\s*\{.*?\n\}\s*",
        "\n",
        text,
        flags=re.S,
    )
    text = re.sub(
        r'(\["showPanel"\]|showPanel)\s*=\s*[^,\n}]+',
        r"\1 = false",
        text,
    )
    if text != orig:
        path.write_text(text, encoding="utf-8")
        print(f"  sanitized ForeverVO prefs in {path.relative_to(root)}")
PY

# Manifest for restore
{
  echo "stamp=$STAMP"
  echo "source_account=$ACCT_NAME"
  echo "source_character=${CHAR_REL:-}"
  echo "wow_forever=$WOW_FOREVER"
  echo "hostname=$(hostname 2>/dev/null || echo unknown)"
} > "$DEST/MANIFEST.txt"

cat > "$DEST/README.md" <<EOF
# Live couch setup snapshot

Captured **$STAMP** from account \`$ACCT_NAME\` / character \`${CHAR_REL:-unknown}\`.

## Contents

- \`account/AddOns.txt\` — enabled couch addons
- \`account/SavedVariables/\` — ConsolePort, Immersion, ForeverVO (audio prefs), QoL
- \`account/bindings-cache.wtf\` — gamepad/key bindings cache
- \`character/\` — per-character ConsolePort bar/target + related SVs
- \`wtf/Config.wtf\` — graphics pins (DX11, 60 FPS, vsync, …)
- \`wtf/GamePadConfig_*.json\` — client gamepad configs

## Restore

On the play box (Forever **fully quit**):

\`\`\`bash
./scripts/restore-live-setup.sh
# optional: map into a different account/character
RESTORE_ACCOUNT=OtherAccount RESTORE_CHARACTER=91/MyChar ./scripts/restore-live-setup.sh
\`\`\`

Then launch Forever. Do **not** commit secrets; this tree excludes capture DBs and passwords.
EOF

echo "Done. Review $DEST then commit from the repo checkout."
