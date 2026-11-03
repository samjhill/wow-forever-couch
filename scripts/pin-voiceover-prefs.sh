#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# WOW_FOREVER provided by lib.sh
WTF_ACCOUNT="${WOW_FOREVER}/WTF/Account"

if [[ ! -d "$WTF_ACCOUNT" ]]; then
  echo "No WTF/Account yet under:"
  echo "  $WTF_ACCOUNT"
  echo "Log into Forever once, then re-run this script."
  exit 0
fi

shopt -s nullglob
immersion_files=("$WTF_ACCOUNT"/*/SavedVariables/Immersion.lua)
fvo_files=("$WTF_ACCOUNT"/*/SavedVariables/ForeverVO.lua)

patched_immersion=0
if ((${#immersion_files[@]} == 0)); then
  echo "No Immersion.lua SavedVariables yet (enable Immersion in-game once, then re-run)."
else
  for f in "${immersion_files[@]}"; do
    python3 - "$f" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8", errors="replace")
orig = text
if re.search(r"\bImmersionSetup\s*=", text):
    if re.search(r"\bttsenabled\s*=", text):
        text = re.sub(r"(\bttsenabled\s*=\s*)[^,\n}]+", r"\1false", text, count=1)
    else:
        text = re.sub(
            r"(\bImmersionSetup\s*=\s*\{)",
            r"\1\n\tttsenabled = false,",
            text,
            count=1,
        )
else:
    text = "ImmersionSetup = {\n\tttsenabled = false,\n}\n" + text
if text != orig:
    path.write_text(text, encoding="utf-8")
    print(f"pinned Immersion TTS off: {path}")
else:
    print(f"already pinned (ttsenabled=false): {path}")
PY
    patched_immersion=$((patched_immersion + 1))
  done
fi

patched_fvo=0
if ((${#fvo_files[@]} == 0)); then
  echo "No ForeverVO.lua SavedVariables yet (defaults already play accept/complete/greeting/gossip)."
else
  for f in "${fvo_files[@]}"; do
    python3 - "$f" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8", errors="replace")
orig = text
# Ensure core play flags stay on if the ForeverVODB table exists
if re.search(r"\bForeverVODB\s*=", text):
    for key in ("playAccept", "playComplete", "playGreeting", "playGossip"):
        if re.search(rf"\b{key}\s*=", text):
            text = re.sub(rf"(\b{key}\s*=\s*)[^,\n}}]+", rf"\1true", text, count=1)
        else:
            text = re.sub(
                r"(\bForeverVODB\s*=\s*\{)",
                rf"\1\n\t{key} = true,",
                text,
                count=1,
            )
if text != orig:
    path.write_text(text, encoding="utf-8")
    print(f"ensured ForeverVO play flags on: {path}")
else:
    print(f"ForeverVO prefs OK (or defaults apply): {path}")
PY
    patched_fvo=$((patched_fvo + 1))
  done
fi

echo "Done. Immersion files: ${patched_immersion}; ForeverVO files: ${patched_fvo}."
echo "If the game is running, fully quit and relaunch so SavedVariables reload."
