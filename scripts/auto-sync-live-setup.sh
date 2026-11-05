#!/usr/bin/env bash
# Periodically snapshot Forever couch prefs from the play box into this repo and
# push when config/live-setup/ changed. Intended for launchd on the Mac that can
# SSH to the box (cloud agents cannot reach the LAN).
#
# Env:
#   BAZZITE_HOST   SSH host (default: bazzite)
#   BAZZITE_REPO   remote checkout/sync dir with scripts/lib.sh (default: ~/Projects/wow-bazzite-setup)
#   AUTO_SYNC_PUSH=0  snapshot+commit locally but do not push
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BAZZITE_HOST="${BAZZITE_HOST:-bazzite}"
BAZZITE_REPO="${BAZZITE_REPO:-Projects/wow-bazzite-setup}"
LOG_PREFIX="[auto-sync-live-setup]"
PUSH="${AUTO_SYNC_PUSH:-1}"

cd "$REPO_ROOT"

log() { printf '%s %s\n' "$LOG_PREFIX" "$*"; }

if ! ssh -o BatchMode=yes -o ConnectTimeout=15 "$BAZZITE_HOST" "true"; then
  log "SSH to $BAZZITE_HOST failed — skip"
  exit 0
fi

# Prefer a clean disk snapshot: note if Forever is still running (SV may be stale).
WOW_RUNNING=$(ssh "$BAZZITE_HOST" "pgrep -f 'Wow\\.exe|WowClassic' >/dev/null && echo yes || echo no" || echo unknown)
if [[ "$WOW_RUNNING" == "yes" ]]; then
  log "Forever appears running — snapshotting last-on-disk SavedVariables (quit Forever to flush new bindings)"
fi

# Keep remote scripts current enough to snapshot
rsync -az \
  "$REPO_ROOT/scripts/snapshot-live-setup.sh" \
  "$REPO_ROOT/scripts/restore-live-setup.sh" \
  "$REPO_ROOT/scripts/lib.sh" \
  "${BAZZITE_HOST}:${BAZZITE_REPO}/scripts/"

ssh "$BAZZITE_HOST" "chmod +x ~/${BAZZITE_REPO}/scripts/snapshot-live-setup.sh && ~/${BAZZITE_REPO}/scripts/snapshot-live-setup.sh"

mkdir -p "$REPO_ROOT/config/live-setup"
rsync -az --delete \
  "${BAZZITE_HOST}:${BAZZITE_REPO}/config/live-setup/" \
  "$REPO_ROOT/config/live-setup/"

if git status --porcelain -- config/live-setup | grep -q .; then
  # Do not mix unrelated local edits into the autosave commit
  if git status --porcelain | grep -vE '^[ M\?][ M\?]? config/live-setup' | grep -q .; then
    log "live-setup changed, but other dirty files exist — leaving unstaged for a human"
    git status --porcelain
    exit 0
  fi

  git add config/live-setup
  STAMP=$(grep '^stamp=' config/live-setup/MANIFEST.txt 2>/dev/null | cut -d= -f2- || date -u +%Y-%m-%dT%H:%MZ)
  git commit -m "$(cat <<EOF
Refresh live couch setup snapshot (${STAMP}).

Autosaved from ${BAZZITE_HOST} while tuning bindings/prefs.
EOF
)"
  if [[ "$PUSH" == "1" ]]; then
    git push origin HEAD
    log "pushed live-setup update (${STAMP})"
  else
    log "committed locally (${STAMP}); push skipped (AUTO_SYNC_PUSH=0)"
  fi
else
  log "no live-setup changes"
fi
