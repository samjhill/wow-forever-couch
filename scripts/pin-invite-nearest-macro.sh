#!/usr/bin/env bash
# Create account macro "InviteNearest" and bind it to Xbox RB (PADRSHOULDER)
# in the Blizzard bindings cache.
# Also parks INTERACTTARGET on LT if that bind is empty (RB previously held Interact).
#
# Forever should be fully quit so macros-cache / bindings-cache are not overwritten.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ACCT="${WOW_FOREVER}/WTF/Account/SAMUHILL"
MACROS="${ACCT}/macros-cache.txt"
BINDINGS="${ACCT}/bindings-cache.wtf"
MACRO_NAME="InviteNearest"
MACRO_ICON="INV_Misc_GroupLooking"
MACRO_BODY=$'/click StaticPopup1Button1\n/targetfriendplayer\n/invite'
BINDING_ACTION="MACRO ${MACRO_NAME}"

if [[ ! -d "$ACCT" ]]; then
  echo "Account folder missing: $ACCT" >&2
  exit 2
fi

if pgrep -f 'WowForever|Wow.exe|WowClassic' >/dev/null 2>&1; then
  echo "WARNING: Forever looks running — quit fully before relying on these files." >&2
fi

mkdir -p "$ACCT"
touch "$MACROS" "$BINDINGS"

python3 - "$MACROS" "$MACRO_NAME" "$MACRO_ICON" "$MACRO_BODY" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
name, icon, body = sys.argv[2], sys.argv[3], sys.argv[4]
text = path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""
# Collect used VER 3 ids
used = {int(x, 16) for x in re.findall(r'^VER 3 ([0-9A-Fa-f]+)', text, re.M)}
new_id = 1
while new_id in used:
    new_id += 1
block = (
    f'VER 3 {new_id:016X} "{name}" "{icon}"\r\n'
    f'{body}\r\n'
    f'END\r\n'
)
# Replace existing macro with same name
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
    # Prefer CRLF like existing Blizzard cache
    if "\r\n" not in text and text:
        text = text.replace("\n", "\r\n")
    text += block
    print(f"added macro {name} id={new_id}")
path.write_text(text, encoding="utf-8")
PY

python3 - "$BINDINGS" "$BINDING_ACTION" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
action = sys.argv[2]
text = path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""

def pin(key: str, act: str, text: str) -> str:
    line = f"bind {key} {act}"
    pat = re.compile(rf'(?im)^bind\s+{re.escape(key)}\s+.*$')
    if pat.search(text):
        return pat.sub(line, text, count=1)
    if text and not text.endswith("\n"):
        text += "\n"
    return text + line + "\n"

text = pin("PADRSHOULDER", action, text)
# Recover Interact if LT is empty / NONE
lt = re.search(r'(?im)^bind\s+PADLTRIGGER\s+(\S+)', text)
if not lt or lt.group(1).upper() in {"NONE", ""}:
    text = pin("PADLTRIGGER", "INTERACTTARGET", text)
    print("pinned PADLTRIGGER INTERACTTARGET (was empty)")
path.write_text(text, encoding="utf-8")
print(f"pinned PADRSHOULDER {action}")
PY

# Mirror into live-setup snapshot when present
LIVE_MACROS="${WOW_COUCH_CONFIG}/live-setup/account/macros-cache.txt"
LIVE_BIND="${WOW_COUCH_CONFIG}/live-setup/account/bindings-cache.wtf"
if [[ -d "${WOW_COUCH_CONFIG}/live-setup/account" ]]; then
  cp -f "$MACROS" "$LIVE_MACROS"
  cp -f "$BINDINGS" "$LIVE_BIND"
  echo "mirrored macros + bindings into config/live-setup/account/"
fi

echo "Done. Fully quit Forever if it was open, then relaunch."
echo "In-game check: RB should be InviteNearest on the Blizzard gamepad bindings."
echo "Macro: ${MACRO_NAME}"
echo "$MACRO_BODY"
