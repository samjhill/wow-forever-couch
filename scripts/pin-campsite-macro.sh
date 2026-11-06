#!/usr/bin/env bash
# Create account macro "Campsite" — plain Forever-safe /use only.
# Forever should be fully quit so macros-cache is not overwritten.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ACCT="${WOW_FOREVER}/WTF/Account/SAMUHILL"
MACROS="${ACCT}/macros-cache.txt"
MACRO_NAME="Campsite"
MACRO_ICON="Spell_Fire_Fire"
MACRO_BODY=$'#showtooltip\n/use Expert Campfire Kit\n/use Journeyman Campfire Kit\n/use Basic Campfire Kit'

if [[ ! -d "$ACCT" ]]; then
  if [[ -d "${WOW_FOREVER}/WTF/Account" ]]; then
    ACCT="$(find "${WOW_FOREVER}/WTF/Account" -mindepth 1 -maxdepth 1 -type d ! -name SavedVariables | head -1 || true)"
    MACROS="${ACCT}/macros-cache.txt"
  fi
fi

if [[ -z "${ACCT:-}" || ! -d "$ACCT" ]]; then
  echo "Account folder missing under ${WOW_FOREVER}/WTF/Account" >&2
  exit 2
fi

if pgrep -f 'WowForever|Wow.exe|WowClassic' >/dev/null 2>&1; then
  echo "WARNING: Forever looks running — quit fully before relying on these files." >&2
fi

mkdir -p "$ACCT"
touch "$MACROS"

python3 - "$MACROS" "$MACRO_NAME" "$MACRO_ICON" "$MACRO_BODY" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
name, icon, body = sys.argv[2], sys.argv[3], sys.argv[4]
text = path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""
used = {int(x, 16) for x in re.findall(r'^VER 3 ([0-9A-Fa-f]+)', text, re.M)}
new_id = 1
while new_id in used:
    new_id += 1
block = (
    f'VER 3 {new_id:016X} "{name}" "{icon}"\r\n'
    f'{body}\r\n'
    f'END\r\n'
)
pat = re.compile(
    rf'^VER 3 [0-9A-Fa-f]+ "{re.escape(name)}" ".*?"\r?\n.*?^END\r?\n',
    re.M | re.S,
)
if pat.search(text):
    text = pat.sub(block, text, count=1)
    print(f"updated macro {name}")
else:
    if text and not text.endswith("\n"):
        text += "\n"
    if "\r\n" not in text and text:
        text = text.replace("\n", "\r\n")
    text += block
    print(f"added macro {name} id={new_id}")
path.write_text(text, encoding="utf-8")
PY

LIVE_MACROS="${WOW_COUCH_CONFIG}/live-setup/account/macros-cache.txt"
if [[ -d "${WOW_COUCH_CONFIG}/live-setup/account" ]]; then
  mkdir -p "$(dirname "$LIVE_MACROS")"
  cp -f "$MACROS" "$LIVE_MACROS"
  echo "mirrored macros into config/live-setup/account/"
fi

echo "Done. Macro body:"
echo "$MACRO_BODY"
echo "Drag Campsite onto the Blizzard gamepad bar."
