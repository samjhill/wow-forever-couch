#!/usr/bin/env bash
# Confirm or cancel a drafted WoW chat line (no keyboard required).
#   confirm (default): KEY_ENTER — send the open edit-box text
#   cancel:            KEY_ESC  — discard / close chat
#
# Set DICTATE_MOCK_FIFO to drive mock-wow-chat.py instead of ydotool.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
EMIT="${REPO_ROOT}/scripts/emit-input-event.sh"
STATUS="${WOW_COUCH_CONFIG}/dictate-status.json"
ACTION="${1:-confirm}"

if [[ -z "${DICTATE_MOCK_FIFO:-}" ]]; then
  RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-$RUNTIME/.ydotool_socket}"
  if [[ ! -S "$YDOTOOL_SOCKET" ]]; then
    echo "ydotoold socket missing: $YDOTOOL_SOCKET (systemctl --user start ydotoold)" >&2
    exit 2
  fi
fi

case "$ACTION" in
  confirm|send|enter)
    "$EMIT" key enter
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
    "$EMIT" key esc
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
