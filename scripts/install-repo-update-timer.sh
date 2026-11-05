#!/usr/bin/env bash
# Install systemd --user timer that pulls this repo and applies safe updates.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

UNIT_DIR="${HOME}/.config/systemd/user"
mkdir -p "$UNIT_DIR"

cat > "${UNIT_DIR}/wow-forever-couch-update.service" <<EOF
[Unit]
Description=Pull wow-forever-couch and apply safe updates
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
WorkingDirectory=${REPO_ROOT}
Environment=WOW_FOREVER_COUCH=${REPO_ROOT}
Environment=WOW_COUCH_UPDATE_MODE=full
Environment=WOW_COUCH_PROFILE=${WOW_COUCH_PROFILE:-}
ExecStart=${REPO_ROOT}/scripts/apply-repo-updates.sh
Nice=10
EOF

cat > "${UNIT_DIR}/wow-forever-couch-update.timer" <<EOF
[Unit]
Description=Periodic wow-forever-couch repo sync (every 6h)

[Timer]
OnBootSec=5min
OnUnitActiveSec=6h
Persistent=true
RandomizedDelaySec=10min

[Install]
WantedBy=timers.target
EOF

chmod +x "${REPO_ROOT}/scripts/apply-repo-updates.sh" "${REPO_ROOT}/scripts/sync-repo-addons.sh"
systemctl --user daemon-reload
systemctl --user enable --now wow-forever-couch-update.timer
systemctl --user --no-pager --full status wow-forever-couch-update.timer | sed -n '1,25p' || true
echo "Timer installed. Manual run: WOW_COUCH_UPDATE_MODE=full ${REPO_ROOT}/scripts/apply-repo-updates.sh"
echo "Launch hook uses quick mode automatically via launch-battlenet-proton.sh"
