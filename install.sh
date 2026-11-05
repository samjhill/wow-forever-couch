#!/usr/bin/env bash
# Curl-friendly entrypoint for Steam Deck / Bazzite / SteamOS-like hosts.
#
#   curl -fsSL https://raw.githubusercontent.com/samjhill/wow-forever-couch/main/install.sh | bash
#
# Or:
#   sh <(curl -fsSL https://raw.githubusercontent.com/samjhill/wow-forever-couch/main/install.sh)
set -euo pipefail

REPO_URL="${WOW_COUCH_REPO_URL:-https://github.com/samjhill/wow-forever-couch.git}"
BRANCH="${WOW_COUCH_BRANCH:-main}"
DEST="${WOW_COUCH_HOME:-$HOME/Projects/wow-forever-couch}"

echo "=== WoW Forever Couch installer ==="
echo "Installing into: $DEST"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required. On Steam Deck Desktop Mode it is usually preinstalled." >&2
  exit 2
fi
if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required." >&2
  exit 2
fi

mkdir -p "$(dirname "$DEST")"
if [[ -d "$DEST/.git" ]]; then
  echo "Existing checkout found — updating $BRANCH…"
  git -C "$DEST" fetch origin "$BRANCH" || git -C "$DEST" fetch origin
  git -C "$DEST" checkout "$BRANCH" 2>/dev/null || true
  git -C "$DEST" pull --ff-only origin "$BRANCH" || {
    echo "Fast-forward failed; continuing with local tree." >&2
  }
elif [[ -d "$DEST" ]]; then
  echo "Directory exists but is not a git repo: $DEST" >&2
  echo "Move it aside or set WOW_COUCH_HOME to another path." >&2
  exit 2
else
  git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$DEST"
fi

chmod +x "$DEST"/scripts/*.sh "$DEST/install.sh" 2>/dev/null || true

# Place a Desktop/launcher icon for re-runs (Dolphin double-click).
if [[ -f "$DEST/scripts/install-desktop-launcher.sh" ]]; then
  "$DEST/scripts/install-desktop-launcher.sh" || true
fi

echo
echo "Running bootstrap (GE-Proton, Battle.net, addons, auto-sync timer)…"
exec "$DEST/scripts/bootstrap-steamos.sh"
