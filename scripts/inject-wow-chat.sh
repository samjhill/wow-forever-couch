#!/usr/bin/env bash
# Inject text into focused WoW chat: Enter → [optional /channel] type → [Enter if send].
# Do NOT send Esc first — Escape opens the game menu.
#
# Env:
#   DICTATE_SEND_MODE=send|draft   send (default): final Enter after typing
#                                  draft: leave text in edit box for a second bind
#   DICTATE_CHANNEL=auto|say|party|raid
#                                  auto (default): bare text; CouchDictateRoute sticky picks channel
#                                  otherwise prefix /say /p /raid as a manual override
#   DICTATE_MOCK_FIFO=path         when set, drive mock-wow-chat.py instead of ydotool
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
EMIT="${REPO_ROOT}/scripts/emit-input-event.sh"

SEND_MODE="${DICTATE_SEND_MODE:-send}"
CHANNEL="${DICTATE_CHANNEL:-auto}"

if [[ -z "${DICTATE_MOCK_FIFO:-}" ]]; then
  RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-$RUNTIME/.ydotool_socket}"
  if [[ ! -S "$YDOTOOL_SOCKET" ]]; then
    echo "ydotoold socket missing: $YDOTOOL_SOCKET (systemctl --user start ydotoold)" >&2
    exit 2
  fi
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

"$EMIT" key enter
sleep 0.05
"$EMIT" type "$PAYLOAD"
sleep 0.03

case "$SEND_MODE_LC" in
  draft|confirm)
    echo "drafted ${#TEXT} chars (channel=${CHANNEL}, mode=draft) — left grip again to send, right grip / Esc to cancel"
    ;;
  send|auto)
    "$EMIT" key enter
    echo "sent ${#TEXT} chars (channel=${CHANNEL}, mode=send)"
    ;;
  *)
    echo "DICTATE_SEND_MODE must be draft|send (got: $SEND_MODE)" >&2
    exit 2
    ;;
esac
