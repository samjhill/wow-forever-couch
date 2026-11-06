#!/usr/bin/env bash
# systemd --user timer: refresh Forever CurseForge addons once a day.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

UNIT_DIR="${HOME}/.config/systemd/user"
mkdir -p "$UNIT_DIR"
chmod +x "${REPO_ROOT}/scripts/update-curseforge-addons.sh"

cat > "${UNIT_DIR}/wow-curseforge-addons.service" <<EOF
[Unit]
Description=Update WoW Forever CurseForge addons
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
WorkingDirectory=${REPO_ROOT}
Environment=WOW_FOREVER_COUCH=${REPO_ROOT}
ExecStart=${REPO_ROOT}/scripts/update-curseforge-addons.sh
Nice=10
EOF

cat > "${UNIT_DIR}/wow-curseforge-addons.timer" <<EOF
[Unit]
Description=CurseForge addon update for WoW Forever (daily)

[Timer]
OnCalendar=04:00
Persistent=true
RandomizedDelaySec=20min

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now wow-curseforge-addons.timer
systemctl --user --no-pager --full status wow-curseforge-addons.timer | sed -n '1,20p' || true
echo "Timer installed. Manual run: ${REPO_ROOT}/scripts/update-curseforge-addons.sh"
