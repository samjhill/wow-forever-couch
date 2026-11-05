#!/usr/bin/env bash
# Pull latest main (ff-only) and apply safe couch updates.
#
# Modes:
#   WOW_COUCH_UPDATE_MODE=quick   (default for launch hook) — git pull + repo addons
#   WOW_COUCH_UPDATE_MODE=full    (timer / manual) — also re-pin prefs; optional live-setup restore
#
# Env:
#   WOW_COUCH_RESTORE_LIVE=1  — also run restore-live-setup.sh (Forever should be quit)
#   WOW_COUCH_SKIP_GIT=1      — do not git pull (apply local tree only)
#   WOW_COUCH_BRANCH=main     — branch to track
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

MODE="${WOW_COUCH_UPDATE_MODE:-quick}"
BRANCH="${WOW_COUCH_BRANCH:-main}"
LOG_PREFIX="[apply-repo-updates]"
LOCK_DIR="${XDG_RUNTIME_DIR:-/tmp}/wow-forever-couch"
LOCK_FILE="${LOCK_DIR}/apply-repo-updates.lock"
mkdir -p "$LOCK_DIR"

log() { printf '%s %s\n' "$LOG_PREFIX" "$*"; }

# Simple non-blocking lock so launch + timer don't overlap.
if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    log "another apply is running — skip"
    exit 0
  fi
fi

cd "$REPO_ROOT"

if [[ "${WOW_COUCH_SKIP_GIT:-0}" != "1" ]]; then
  if [[ -d "$REPO_ROOT/.git" ]]; then
    git fetch origin "$BRANCH" 2>/dev/null || git fetch origin || true
    if git rev-parse --verify "origin/${BRANCH}" >/dev/null 2>&1; then
      if ! git merge-base --is-ancestor HEAD "origin/${BRANCH}" 2>/dev/null; then
        # allow already-up-to-date or behind
        true
      fi
      if ! git pull --ff-only origin "$BRANCH"; then
        log "git pull --ff-only failed — leave tree alone (resolve locally)"
        # Still try addon sync from current tree
      else
        log "pulled origin/${BRANCH}"
      fi
    else
      log "no origin/${BRANCH} — skip pull"
    fi
  else
    log "not a git checkout — skip pull"
  fi
fi

# Never touch WTF while Forever is running (except repo addon file copies are OK;
# enable/pin scripts that rewrite SavedVariables are full-mode only and still risky).
WOW_RUNNING=0
if pgrep -f 'Wow\.exe|WowForever|WowClassic' >/dev/null 2>&1; then
  WOW_RUNNING=1
  log "Forever appears running"
fi

if [[ -d "$WOW_ADDONS" ]]; then
  chmod +x "${REPO_ROOT}/scripts/"*.sh 2>/dev/null || true
  "${REPO_ROOT}/scripts/sync-repo-addons.sh" || log "sync-repo-addons reported errors"
else
  log "Forever AddOns missing — skip addon sync (install Forever first)"
fi

if [[ "$MODE" == "full" ]]; then
  if [[ -d "$WOW_FOREVER" ]]; then
    if [[ -x "${REPO_ROOT}/scripts/pin-voiceover-prefs.sh" && "$WOW_RUNNING" -eq 0 ]]; then
      "${REPO_ROOT}/scripts/pin-voiceover-prefs.sh" || true
    fi
    if [[ -x "${REPO_ROOT}/scripts/pin-forever-graphics.sh" ]]; then
      "${REPO_ROOT}/scripts/pin-forever-graphics.sh" || true
    fi
  fi
  if [[ "${WOW_COUCH_RESTORE_LIVE:-0}" == "1" ]]; then
    if [[ "$WOW_RUNNING" -eq 1 ]]; then
      log "WOW_COUCH_RESTORE_LIVE=1 but Forever is running — skip restore"
    elif [[ -x "${REPO_ROOT}/scripts/restore-live-setup.sh" ]]; then
      log "restoring config/live-setup (opt-in)"
      "${REPO_ROOT}/scripts/restore-live-setup.sh" || true
    fi
  fi
fi

log "done (mode=${MODE} profile=${WOW_COUCH_PROFILE:-default})"
