#!/usr/bin/env bash
# One-shot Steam Deck / Bazzite / SteamOS-like couch bootstrap.
#
# Desktop Mode recommended. After this finishes:
#   1) Log into Battle.net if the window asks (only typing step)
#   2) Wait for Forever download (script polls _forever_)
#   3) Gaming Mode → "Battle.net (WoW Forever)" (shortcut written automatically)
#
# Can also be invoked after: git clone … && ./scripts/bootstrap-steamos.sh
# Or: curl …/install.sh | bash
set -euo pipefail

DEFAULT_CLONE="${HOME}/Projects/wow-forever-couch"
REPO_URL="${WOW_COUCH_REPO_URL:-https://github.com/samjhill/wow-forever-couch.git}"

resolve_repo() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  if [[ -f "${here}/scripts/lib.sh" ]]; then
    echo "$here"
    return
  fi
  if [[ -f "${DEFAULT_CLONE}/scripts/lib.sh" ]]; then
    echo "$DEFAULT_CLONE"
    return
  fi
  echo ""
}

REPO="$(resolve_repo)"
if [[ -z "$REPO" ]]; then
  echo "Cloning ${REPO_URL} → ${DEFAULT_CLONE}"
  mkdir -p "$(dirname "$DEFAULT_CLONE")"
  git clone "$REPO_URL" "$DEFAULT_CLONE"
  REPO="$DEFAULT_CLONE"
fi

cd "$REPO"
chmod +x scripts/*.sh scripts/*.py 2>/dev/null || true
# shellcheck source=lib.sh
source "${REPO}/scripts/lib.sh"

echo "=== wow-forever-couch bootstrap ==="
echo "REPO_ROOT=$REPO_ROOT"
echo "profile=${WOW_COUCH_PROFILE:-default}"
echo "prefix=$WOW_PREFIX"

# Lightweight host packages when available (ignore failures on immutable OS).
if command -v rpm-ostree >/dev/null 2>&1; then
  echo "(rpm-ostree host — prefer layered packages already present; skipping system install)"
elif command -v pacman >/dev/null 2>&1; then
  echo "Ensuring curl git python3…"
  sudo pacman -S --needed --noconfirm curl git python3 2>/dev/null || true
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get install -y curl git python3 2>/dev/null || true
fi

echo "=== GE-Proton ==="
"${REPO_ROOT}/scripts/install-ge-proton.sh"
# Refresh resolver after install may have added a new tool.
WOW_PROTON="$(resolve_ge_proton)"
if [[ -n "$WOW_PROTON" ]]; then
  export WOW_COMPAT_TOOL="$(cd "$(dirname "$WOW_PROTON")" && pwd)"
  export WOW_PROTON
fi

echo "=== Battle.net prefix ==="
"${REPO_ROOT}/scripts/install-battlenet-desktop.sh"

echo "=== WoW Forever client ==="
if forever_client_ready; then
  echo "Forever already present: $WOW_FOREVER"
else
  "${REPO_ROOT}/scripts/install-forever-client.sh" || {
    echo "Forever not ready yet. Log into Battle.net, install Forever, then re-run bootstrap." >&2
  }
fi

if forever_client_ready; then
  echo "=== Forever client found — installing addons ==="
  "${REPO_ROOT}/scripts/install-forever-addons.sh" || true
  "${REPO_ROOT}/scripts/install-forever-qol-addons.sh" || true
  "${REPO_ROOT}/scripts/sync-repo-addons.sh" || true
  if [[ -d "${WOW_FOREVER}/WTF/Account" ]]; then
    "${REPO_ROOT}/scripts/enable-forever-addons.sh" || true
    "${REPO_ROOT}/scripts/pin-voiceover-prefs.sh" || true
  else
    echo "No WTF/Account yet — first in-game login creates it; launch script will enable addons after that."
  fi
  "${REPO_ROOT}/scripts/pin-forever-graphics.sh" || true
  if [[ "${WOW_COUCH_RESTORE_LIVE:-0}" == "1" ]]; then
    "${REPO_ROOT}/scripts/restore-live-setup.sh" || true
  fi
else
  echo "=== Forever not installed yet — skipping addon install ==="
fi

echo "=== Auto-update timer ==="
"${REPO_ROOT}/scripts/install-repo-update-timer.sh"
"${REPO_ROOT}/scripts/install-curseforge-update-timer.sh"

if [[ "${WOW_COUCH_DICTATION:-0}" == "1" ]]; then
  echo "=== Dictation (opt-in) ==="
  "${REPO_ROOT}/scripts/setup-whisper.sh" || true
  "${REPO_ROOT}/scripts/install-user-services.sh" || true
  "${REPO_ROOT}/scripts/prefer-mic-source.sh" || true
else
  echo "Dictation skipped (set WOW_COUCH_DICTATION=1 to enable)."
fi

# Desktop + app-menu launcher for re-runs
"${REPO_ROOT}/scripts/install-desktop-launcher.sh" || true

echo "=== Steam Gaming Mode shortcut ==="
if [[ "${WOW_COUCH_SKIP_STEAM_SHORTCUT:-0}" == "1" ]]; then
  echo "Skipped (WOW_COUCH_SKIP_STEAM_SHORTCUT=1)."
else
  "${REPO_ROOT}/scripts/add-steam-shortcut.sh" || {
    echo "Shortcut helper failed — manual steps: ${REPO_ROOT}/scripts/add-steam-shortcut.md" >&2
  }
fi

echo
echo "=== Done ==="
echo "Only typing left: Battle.net login (if the window is still open)."
echo "Gaming Mode → launch: Battle.net (WoW Forever)"
echo "Docs: ${REPO_ROOT}/docs/steam-deck.md"
echo "Sync now:  WOW_COUCH_UPDATE_MODE=full ${REPO_ROOT}/scripts/apply-repo-updates.sh"
