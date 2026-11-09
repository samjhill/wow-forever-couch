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
# CurseForge addon zips refresh on the daily timer, not here, so launch does not wait on downloads.
if [[ "${WOW_COUCH_LAUNCH_SYNC:-1}" == "1" && -x "${REPO_ROOT}/scripts/apply-repo-updates.sh" ]]; then
  WOW_COUCH_UPDATE_MODE=quick "${REPO_ROOT}/scripts/apply-repo-updates.sh" >/tmp/wow-forever-couch-launch-sync.log 2>&1 || true
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

# App setting: When launching a game → Exit Battle.net completely, after the game is up.
# 0 minimize, 1 keep open, 2 exit. DelayedExit waits until Wow.exe is running.
_bnet_cfg="${WOW_PREFIX}/pfx/drive_c/users/steamuser/AppData/Roaming/Battle.net/Battle.net.config"
if [[ -f "${_bnet_cfg}" ]]; then
  python3 - "${_bnet_cfg}" << 'PY' || true
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as fh:
    cfg = json.load(fh)
client = cfg.setdefault("Client", {})
client["GameLaunchWindowBehavior"] = "2"
client["DelayedExitAppOnLaunch"] = "true"
with open(path, "w", encoding="utf-8") as fh:
    json.dump(cfg, fh, indent=4)
    fh.write("\n")
PY
fi
unset _bnet_cfg

if [[ "${XDG_CURRENT_DESKTOP:-}" == *plasma* || "${DESKTOP_SESSION:-}" == *plasma* ]]; then
  echo "Note: Desktop/Plasma session detected. For fewer screen tears, play from Gaming Mode:" >&2
  echo "  steamos-session-select gamescope" >&2
fi

# Steam Deck Desktop: the Qt/CEF sign-in view is black under Xwayland (ANGLE on DXVK).
# Software Qt plus disabled hardware acceleration paints it. Gaming Mode keeps the GPU renderer.
if [[ "${WOW_COUCH_PROFILE:-}" == "deck" && -z "${GAMESCOPE_WAYLAND_DISPLAY:-}" ]]; then
  export QT_QUICK_BACKEND="${QT_QUICK_BACKEND:-software}"
  export QT_ANGLE_PLATFORM="${QT_ANGLE_PLATFORM:-warp}"
  # X11 desktop: 32-bit CEF's GPU process exits under DXVK ("GPU process isn't usable").
  # WineD3D lets that process use SwiftShader. A Wayland session and Gaming Mode keep DXVK.
  if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    export PROTON_USE_WINED3D="${PROTON_USE_WINED3D:-1}"
  fi
  _bnet_cfg="${WOW_PREFIX}/pfx/drive_c/users/steamuser/AppData/Roaming/Battle.net/Battle.net.config"
  if [[ -f "${_bnet_cfg}" ]]; then
    python3 - "${_bnet_cfg}" << 'PY' || true
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as fh:
    cfg = json.load(fh)
client = cfg.setdefault("Client", {})
client["HardwareAcceleration"] = "false"
client["QtHardwareAcceleration"] = "false"
with open(path, "w", encoding="utf-8") as fh:
    json.dump(cfg, fh, indent=4)
    fh.write("\n")
PY
  fi
  unset _bnet_cfg
fi

if [[ -x "${REPO_ROOT}/scripts/fix-proton-gnutls.sh" ]]; then
  "${REPO_ROOT}/scripts/fix-proton-gnutls.sh" || true
fi

cd "$(dirname "$EXE")"
exec "$WOW_PROTON" run "$EXE" "$@"
