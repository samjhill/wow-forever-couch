#!/usr/bin/env bash
# Add Gaming Mode non-Steam shortcut for Battle.net (WoW Forever) with Steam Input on.
# Steam must be signed in at least once (userdata present). Restarts Steam so the
# library picks up shortcuts.vdf changes.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

NAME="${WOW_COUCH_STEAM_NAME:-Battle.net (WoW Forever)}"
EXE="${REPO_ROOT}/scripts/launch-battlenet-lutris.sh"
START_DIR="${REPO_ROOT}/scripts"
PY="${REPO_ROOT}/scripts/add-steam-shortcut.py"

if [[ ! -f "$EXE" ]]; then
  echo "missing launch script: $EXE" >&2
  exit 2
fi
if [[ ! -f "$PY" ]]; then
  echo "missing $PY" >&2
  exit 2
fi
chmod +x "$EXE" "$PY" 2>/dev/null || true

steam_running=0
if pgrep -x steam >/dev/null 2>&1 || pgrep -f '/steam(\.sh)?( |$)' >/dev/null 2>&1; then
  steam_running=1
fi

if [[ "$steam_running" -eq 1 ]]; then
  echo "Shutting down Steam so shortcuts.vdf can be written…"
  if command -v steam >/dev/null 2>&1; then
    steam -shutdown >/dev/null 2>&1 || true
  else
    pkill -x steam 2>/dev/null || true
  fi
  # Wait up to ~30s for clean exit
  for _ in $(seq 1 30); do
    if ! pgrep -x steam >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
  sleep 1
fi

set +e
python3 "$PY" --name "$NAME" --exe "$EXE" --start-dir "$START_DIR"
rc=$?
set -e

if [[ "$rc" -eq 3 ]]; then
  echo "Sign into Steam once in Desktop Mode, then re-run:" >&2
  echo "  ${REPO_ROOT}/scripts/add-steam-shortcut.sh" >&2
  exit 3
fi
if [[ "$rc" -ne 0 ]]; then
  echo "Automatic shortcut failed (exit $rc)." >&2
  echo "Manual fallback: Steam → Games → Add a Non-Steam Game →" >&2
  echo "  $EXE" >&2
  echo "Rename to: $NAME. Do NOT force Steam Proton. Enable Steam Input." >&2
  exit "$rc"
fi

# Restart Steam if it was running (or always try — helps Gaming Mode see the entry).
if command -v steam >/dev/null 2>&1; then
  if [[ "$steam_running" -eq 1 || "${WOW_COUCH_RESTART_STEAM:-1}" == "1" ]]; then
    echo "Starting Steam…"
    nohup steam >/tmp/wow-forever-couch-steam-restart.log 2>&1 &
    disown || true
  fi
fi

echo "Done. In Gaming Mode launch: $NAME"
