#!/usr/bin/env bash
# Install ydotoold + dictate-daemon as systemd --user units.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

UNIT_DIR="${HOME}/.config/systemd/user"
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
SOCK="${RUNTIME}/.ydotool_socket"
mkdir -p "$UNIT_DIR"

cat > "${UNIT_DIR}/ydotoold.service" <<EOF
[Unit]
Description=ydotool input daemon (uinput) for WoW dictation inject
After=default.target

[Service]
Type=simple
ExecStart=/usr/bin/ydotoold -p ${SOCK} -P 0600
Restart=on-failure
RestartSec=1
Environment=YDOTOOL_SOCKET=${SOCK}

[Install]
WantedBy=default.target
EOF

cat > "${UNIT_DIR}/wow-dictate-daemon.service" <<EOF
[Unit]
Description=WoW Forever dictation trigger daemon (SC grip / Xbox R3 / Insert / FIFO)
After=default.target sound.target ydotoold.service

[Service]
Type=simple
ExecStart=/usr/bin/python3 ${REPO_ROOT}/scripts/dictate-daemon.py
Restart=on-failure
RestartSec=2
Environment=WOW_FOREVER_COUCH=${REPO_ROOT}
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now ydotoold.service
systemctl --user enable --now wow-dictate-daemon.service
systemctl --user --no-pager --full status ydotoold.service wow-dictate-daemon.service | sed -n '1,40p'
echo "Services installed from REPO_ROOT=${REPO_ROOT}"
