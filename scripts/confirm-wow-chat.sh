#!/usr/bin/env bash
# Confirm or cancel a drafted WoW chat line (no keyboard required).
#   confirm (default): KEY_ENTER — send the open edit-box text
#   cancel:            KEY_ESC  — discard / close chat
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-$RUNTIME/.ydotool_socket}"
STATUS="${WOW_COUCH_CONFIG}/dictate-status.json"
ACTION="${1:-confirm}"

if [[ ! -S "$YDOTOOL_SOCKET" ]]; then
  echo "ydotoold socket missing: $YDOTOOL_SOCKET (systemctl --user start ydotoold)" >&2
  exit 2
fi

case "$ACTION" in
  confirm|send|enter)
    # KEY_ENTER=28
    ydotool key 28:1 28:0
    python3 - "$STATUS" <<'PY'
import json, sys, time
path = sys.argv[1]
data = {}
try:
    data = json.load(open(path))
except Exception:
    pass
data.update({"state": "sent", "ts": time.time(), "detail": "confirmed via grip/FIFO"})
json.dump(data, open(path, "w"), indent=2)
print("status=sent", flush=True)
PY
    echo "confirmed chat send (Enter)"
    ;;
  cancel|esc|discard)
    # KEY_ESC=1
    ydotool key 1:1 1:0
    python3 - "$STATUS" <<'PY'
import json, sys, time
path = sys.argv[1]
data = {}
try:
    data = json.load(open(path))
except Exception:
    pass
data.update({"state": "cancelled", "ts": time.time(), "detail": "draft cancelled"})
json.dump(data, open(path, "w"), indent=2)
print("status=cancelled", flush=True)
PY
    echo "cancelled chat draft (Esc)"
    ;;
  *)
    echo "usage: $0 [confirm|cancel]" >&2
    exit 2
    ;;
esac
