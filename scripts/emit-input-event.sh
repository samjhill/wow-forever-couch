#!/usr/bin/env bash
# Emit one input event either to the mock-wow FIFO or via ydotool.
# Usage:
#   emit-input-event.sh key esc|enter
#   emit-input-event.sh type "text here"
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

MODE="${1:-}"
ARG="${2:-}"
MOCK_FIFO="${DICTATE_MOCK_FIFO:-}"

emit_mock() {
  local json="$1"
  if [[ -z "$MOCK_FIFO" ]]; then
    echo "DICTATE_MOCK_FIFO unset" >&2
    exit 2
  fi
  # Ensure FIFO exists (mock creates it; wait briefly)
  local i
  for ((i = 0; i < 50; i++)); do
    [[ -p "$MOCK_FIFO" ]] && break
    sleep 0.05
  done
  if [[ ! -p "$MOCK_FIFO" ]]; then
    echo "mock FIFO missing: $MOCK_FIFO" >&2
    exit 2
  fi
  printf '%s\n' "$json" >"$MOCK_FIFO"
}

emit_ydotool_key() {
  local key="$1"
  RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-$RUNTIME/.ydotool_socket}"
  if [[ ! -S "$YDOTOOL_SOCKET" ]]; then
    echo "ydotoold socket missing: $YDOTOOL_SOCKET" >&2
    exit 2
  fi
  case "$key" in
    esc|escape) ydotool key 1:1 1:0 ;;
    enter|return) ydotool key 28:1 28:0 ;;
    *)
      echo "unknown key: $key" >&2
      exit 2
      ;;
  esac
}

case "$MODE" in
  key)
    if [[ -n "$MOCK_FIFO" ]]; then
      emit_mock "$(printf '{"type":"key","key":"%s"}' "$ARG")"
    else
      emit_ydotool_key "$ARG"
    fi
    ;;
  type)
    if [[ -n "$MOCK_FIFO" ]]; then
      # JSON-escape via python
      py="$(python3 -c 'import json,sys; print(json.dumps({"type":"type","text":sys.argv[1]}))' "$ARG")"
      emit_mock "$py"
    else
      RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-$RUNTIME/.ydotool_socket}"
      if [[ ! -S "$YDOTOOL_SOCKET" ]]; then
        echo "ydotoold socket missing: $YDOTOOL_SOCKET" >&2
        exit 2
      fi
      printf '%s' "$ARG" | ydotool type --file -
    fi
    ;;
  *)
    echo "usage: $0 key esc|enter | type TEXT" >&2
    exit 2
    ;;
esac
