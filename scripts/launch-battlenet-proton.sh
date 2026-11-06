#!/usr/bin/env bash
# Launch Battle.net under GE-Proton. Extra args are forwarded (e.g. --game=WoWF --install).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

export STEAM_COMPAT_CLIENT_INSTALL_PATH="${HOME}/.local/share/Steam"
export STEAM_COMPAT_DATA_PATH="${WOW_PREFIX}"

if [[ -z "${WOW_PROTON:-}" || ! -x "$WOW_PROTON" ]]; then
  WOW_PROTON="$(resolve_ge_proton)"
fi
if [[ -z "${WOW_PROTON:-}" || ! -x "$WOW_PROTON" ]]; then
  echo "GE-Proton not found. Run scripts/install-ge-proton.sh first." >&2
  exit 1
fi

EXE="$(find_battlenet_exe || true)"
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

# Quiet repo sync before Battle.net (ff-only pull + repo-owned addons). Timer does full mode.
if [[ "${WOW_COUCH_LAUNCH_SYNC:-1}" == "1" && -x "${REPO_ROOT}/scripts/apply-repo-updates.sh" ]]; then
  WOW_COUCH_UPDATE_MODE=quick "${REPO_ROOT}/scripts/apply-repo-updates.sh" >/tmp/wow-forever-couch-launch-sync.log 2>&1 || true
fi

# CurseForge Forever files before the client starts. Skip with WOW_COUCH_CURSEFORGE_UPDATE=0.
if [[ "${WOW_COUCH_CURSEFORGE_UPDATE:-1}" == "1" && -x "${REPO_ROOT}/scripts/update-curseforge-addons.sh" ]]; then
  if command -v timeout >/dev/null 2>&1; then
    timeout 600 "${REPO_ROOT}/scripts/update-curseforge-addons.sh" || true
  else
    "${REPO_ROOT}/scripts/update-curseforge-addons.sh" || true
  fi
fi

# After first in-game login, WTF/Account exists — enable couch addons without a second bootstrap.
if [[ -d "${WOW_FOREVER}/WTF/Account" ]]; then
  if [[ -x "${REPO_ROOT}/scripts/enable-forever-addons.sh" ]]; then
    "${REPO_ROOT}/scripts/enable-forever-addons.sh" >/tmp/wow-forever-couch-enable-addons.log 2>&1 || true
  fi
  if [[ -x "${REPO_ROOT}/scripts/pin-voiceover-prefs.sh" ]]; then
    "${REPO_ROOT}/scripts/pin-voiceover-prefs.sh" >/tmp/wow-forever-couch-pin-voiceover.log 2>&1 || true
  fi
  if [[ -x "${REPO_ROOT}/scripts/pin-wand-macro.sh" ]]; then
    "${REPO_ROOT}/scripts/pin-wand-macro.sh" >/tmp/wow-forever-couch-pin-wand.log 2>&1 || true
  fi
fi

if [[ "${XDG_CURRENT_DESKTOP:-}" == *plasma* || "${DESKTOP_SESSION:-}" == *plasma* ]]; then
  echo "Note: Desktop/Plasma session detected. For fewer screen tears, play from Gaming Mode:" >&2
  echo "  steamos-session-select gamescope" >&2
fi

cd "$(dirname "$EXE")"
exec "$WOW_PROTON" run "$EXE" "$@"
