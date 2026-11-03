#!/usr/bin/env bash
# Inject text into focused WoW chat: Esc → Enter → [optional /channel] type → [Enter if send].
#
# Env:
#   DICTATE_SEND_MODE=draft|send   draft (default): leave text in edit box for confirm
#                                  send: press final Enter to submit
#   DICTATE_CHANNEL=auto|say|party|raid
#                                  auto (default): bare text; CouchDictateRoute sticky picks channel
#                                  otherwise prefix /say /p /raid as a manual override
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-$RUNTIME/.ydotool_socket}"

SEND_MODE="${DICTATE_SEND_MODE:-draft}"
CHANNEL="${DICTATE_CHANNEL:-auto}"

if [[ ! -S "$YDOTOOL_SOCKET" ]]; then
  echo "ydotoold socket missing: $YDOTOOL_SOCKET (systemctl --user start ydotoold)" >&2
  exit 2
fi

if [[ $# -gt 0 ]]; then
  TEXT="$*"
else
  TEXT="$(cat)"
fi

# Normalize: trim, collapse newlines/whitespace to single spaces
TEXT="$(printf '%s' "$TEXT" | tr '\n\r\t' ' ' | sed -E 's/  +/ /g; s/^ //; s/ $//')"
if [[ -z "$TEXT" ]]; then
  echo "refuse empty transcript" >&2
  exit 3
fi

CHANNEL_LC="$(printf '%s' "$CHANNEL" | tr '[:upper:]' '[:lower:]')"
SEND_MODE_LC="$(printf '%s' "$SEND_MODE" | tr '[:upper:]' '[:lower:]')"

PREFIX=""
case "$CHANNEL_LC" in
  auto|"") PREFIX="" ;;
  say|s) PREFIX="/say " ;;
  party|p) PREFIX="/p " ;;
  raid|r) PREFIX="/raid " ;;
  *)
    echo "DICTATE_CHANNEL must be auto|say|party|raid (got: $CHANNEL)" >&2
    exit 2
    ;;
esac

PAYLOAD="${PREFIX}${TEXT}"

# KEY_ESC=1 KEY_ENTER=28
ydotool key 1:1 1:0
sleep 0.15
ydotool key 28:1 28:0
sleep 0.25
printf '%s' "$PAYLOAD" | ydotool type --file -
sleep 0.12

case "$SEND_MODE_LC" in
  draft|confirm)
    echo "drafted ${#TEXT} chars (channel=${CHANNEL}, mode=draft) — left grip again to send, right grip / Esc to cancel"
    ;;
  send|auto)
    ydotool key 28:1 28:0
    echo "sent ${#TEXT} chars (channel=${CHANNEL}, mode=send)"
    ;;
  *)
    echo "DICTATE_SEND_MODE must be draft|send (got: $SEND_MODE)" >&2
    exit 2
    ;;
esac
