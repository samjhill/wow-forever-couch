#!/usr/bin/env bash
# One-shot Steam Deck / Bazzite / SteamOS-like couch bootstrap.
#
# Desktop Mode recommended. After this finishes:
#   1) Launch Battle.net, log in, install Forever (not Retail)
#   2) Run this script again (or apply-repo-updates) once _forever_ exists
#   3) Gaming Mode → non-Steam "Battle.net (WoW Forever)" → enable Steam Input
#
# Can also be invoked after: git clone … && ./scripts/bootstrap-steamos.sh
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
chmod +x scripts/*.sh 2>/dev/null || true
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

echo "=== Battle.net prefix ==="
if ! find "${WOW_PREFIX}/pfx" -name 'Battle.net.exe' 2>/dev/null | grep -q .; then
  "${REPO_ROOT}/scripts/install-battlenet-desktop.sh" || {
    echo "Battle.net installer needs Desktop Mode interaction. Re-run bootstrap after it finishes." >&2
  }
else
  echo "Battle.net already present under $WOW_PREFIX"
fi

if [[ -d "$WOW_FOREVER" ]]; then
  echo "=== Forever client found — installing addons ==="
  "${REPO_ROOT}/scripts/install-forever-addons.sh" || true
  "${REPO_ROOT}/scripts/install-forever-qol-addons.sh" || true
  "${REPO_ROOT}/scripts/sync-repo-addons.sh" || true
  if [[ -d "${WOW_FOREVER}/WTF/Account" ]]; then
    "${REPO_ROOT}/scripts/enable-forever-addons.sh" || true
    "${REPO_ROOT}/scripts/pin-voiceover-prefs.sh" || true
  else
    echo "No WTF/Account yet — log into Forever once, then re-run bootstrap or:"
    echo "  ./scripts/enable-forever-addons.sh && ./scripts/pin-voiceover-prefs.sh"
  fi
  "${REPO_ROOT}/scripts/pin-forever-graphics.sh" || true
  if [[ "${WOW_COUCH_RESTORE_LIVE:-0}" == "1" ]]; then
    "${REPO_ROOT}/scripts/restore-live-setup.sh" || true
  fi
else
  echo "=== Forever not installed yet ==="
  echo "Next: ./scripts/launch-battlenet-proton.sh → log in → install Forever → re-run this bootstrap."
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

echo
echo "=== Done ==="
echo "Steam shortcut (Desktop Mode): Games → Add Non-Steam Game →"
echo "  ${REPO_ROOT}/scripts/launch-battlenet-lutris.sh"
echo "Rename to: Battle.net (WoW Forever). Do NOT force Steam Proton. Enable Steam Input."
echo "Docs: ${REPO_ROOT}/docs/steam-deck.md"
echo "Sync now:  WOW_COUCH_UPDATE_MODE=full ${REPO_ROOT}/scripts/apply-repo-updates.sh"
