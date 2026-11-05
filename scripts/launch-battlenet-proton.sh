#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="${HOME}/.local/share/Steam"
export STEAM_COMPAT_DATA_PATH="${WOW_PREFIX}"
PROTON="${HOME}/.local/share/Steam/compatibilitytools.d/GE-Proton11-12/proton"
EXE="${STEAM_COMPAT_DATA_PATH}/pfx/drive_c/Program Files (x86)/Battle.net/Battle.net.exe"
if [[ ! -f "$EXE" ]]; then
  EXE=$(find "${STEAM_COMPAT_DATA_PATH}/pfx" -name 'Battle.net.exe' 2>/dev/null | head -1 || true)
fi
if [[ -z "${EXE:-}" || ! -f "$EXE" ]]; then
  echo "Battle.net.exe not found. Run scripts/install-battlenet-desktop.sh from Desktop Mode first." >&2
  exit 1
fi

# Stable Forever on NVIDIA + Proton (see docs/troubleshooting.md#graphics--audio).
# DX11 is pinned in Config.wtf; these env vars help DXVK pacing + HDMI audio under CPU load.
export DXVK_FRAME_RATE="${DXVK_FRAME_RATE:-60}"
export DXVK_HUD="${DXVK_HUD:-}"  # leave empty unless debugging
export __GL_SYNC_TO_VBLANK="${__GL_SYNC_TO_VBLANK:-1}"
export __GL_VRR_ALLOWED="${__GL_VRR_ALLOWED:-0}"
export __GL_GSYNC_ALLOWED="${__GL_GSYNC_ALLOWED:-0}"
export PULSE_LATENCY_MSEC="${PULSE_LATENCY_MSEC:-60}"

if [[ -x "${REPO_ROOT}/scripts/pin-forever-graphics.sh" ]]; then
  "${REPO_ROOT}/scripts/pin-forever-graphics.sh" || true
fi

if [[ "${XDG_CURRENT_DESKTOP:-}" == *plasma* || "${DESKTOP_SESSION:-}" == *plasma* ]]; then
  echo "Note: Desktop/Plasma session detected. For fewer screen tears, play from Gaming Mode:" >&2
  echo "  steamos-session-select gamescope" >&2
fi

cd "$(dirname "$EXE")"
exec "$PROTON" run "$EXE"
