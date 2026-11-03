#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
echo "=== USB ==="
lsusb
echo "=== PipeWire sources ==="
wpctl status || true
OUT="/tmp/wow-mic-test.wav"
echo "Recording 3s to $OUT (Ctrl+C to abort)..."
if command -v pw-record >/dev/null; then
  pw-record --target @DEFAULT_SOURCE@ "$OUT" &
  PID=$!
  sleep 3
  kill "$PID" 2>/dev/null || true
  wait "$PID" 2>/dev/null || true
  ls -la "$OUT"
  echo "Play back with: pw-play $OUT"
else
  echo "pw-record not found"
  exit 1
fi
