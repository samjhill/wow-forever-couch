#!/usr/bin/env bash
# Restore config/live-setup/ into the live Forever WTF tree.
# Forever must be fully quit. Defaults to the first account + first character
# under WTF/Account, or RESTORE_ACCOUNT / RESTORE_CHARACTER overrides.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

SRC="${WOW_COUCH_CONFIG}/live-setup"
WTF="${WOW_FOREVER}/WTF"
ACCT_ROOT="${WTF}/Account"

if [[ ! -d "$SRC/account" ]]; then
  echo "Missing snapshot at $SRC — run scripts/snapshot-live-setup.sh first." >&2
  exit 2
fi
if [[ ! -d "$ACCT_ROOT" ]]; then
  echo "No WTF/Account yet. Log into Forever once, then re-run." >&2
  exit 2
fi

if [[ -n "${RESTORE_ACCOUNT:-}" ]]; then
  ACCT="${ACCT_ROOT}/${RESTORE_ACCOUNT}"
else
  ACCT=""
  for d in "$ACCT_ROOT"/*/; do
    base=$(basename "$d")
    [[ "$base" == "SavedVariables" ]] && continue
    ACCT="$d"
    break
  done
fi
ACCT="${ACCT%/}"
if [[ ! -d "$ACCT" ]]; then
  echo "Account folder not found: $ACCT" >&2
  exit 2
fi

if [[ -n "${RESTORE_CHARACTER:-}" ]]; then
  CHAR_DIR="${ACCT}/${RESTORE_CHARACTER}"
else
  CHAR_DIR=""
  shopt -s nullglob
  for f in "$ACCT"/*/*/AddOns.txt; do
    CHAR_DIR=$(dirname "$f")
    break
  done
fi

echo "Restore from $SRC"
echo "  → account $ACCT"
[[ -n "$CHAR_DIR" ]] && echo "  → character $CHAR_DIR"

mkdir -p "$ACCT/SavedVariables"
cp -a "$SRC/account/AddOns.txt" "$ACCT/AddOns.txt"
[[ -f "$SRC/account/bindings-cache.wtf" ]] && cp -a "$SRC/account/bindings-cache.wtf" "$ACCT/bindings-cache.wtf"
if [[ -d "$SRC/account/SavedVariables" ]]; then
  cp -a "$SRC/account/SavedVariables/." "$ACCT/SavedVariables/"
fi

if [[ -n "$CHAR_DIR" && -d "$SRC/character" ]]; then
  mkdir -p "$CHAR_DIR/SavedVariables"
  [[ -f "$SRC/character/AddOns.txt" ]] && cp -a "$SRC/character/AddOns.txt" "$CHAR_DIR/AddOns.txt"
  if [[ -d "$SRC/character/SavedVariables" ]]; then
    cp -a "$SRC/character/SavedVariables/." "$CHAR_DIR/SavedVariables/"
  fi
fi

if [[ -d "$SRC/wtf" ]]; then
  mkdir -p "$WTF"
  for f in Config.wtf gamecontrollerdb.txt GamePadConfig_Addons.json GamePadConfig_Default.json; do
    [[ -f "$SRC/wtf/$f" ]] && cp -a "$SRC/wtf/$f" "$WTF/$f"
  done
fi

echo "Restored. Launch Forever (full restart). Re-run pin scripts if you want policy overlays:"
echo "  ./scripts/pin-voiceover-prefs.sh"
echo "  ./scripts/pin-forever-graphics.sh"
echo "  ./scripts/pin-wand-macro.sh"
echo "  ./scripts/enable-forever-addons.sh"
