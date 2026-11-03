#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-$RUNTIME/.ydotool_socket}"

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

# KEY_ESC=1 KEY_ENTER=28
ydotool key 1:1 1:0
sleep 0.15
ydotool key 28:1 28:0
sleep 0.25
# Type transcript (file avoids shell quoting issues)
printf '%s' "$TEXT" | ydotool type --file -
sleep 0.12
ydotool key 28:1 28:0
echo "injected ${#TEXT} chars into chat"
