#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
echo "=== session ==="
loginctl show-session 1 -p Type -p Desktop 2>/dev/null || true
echo "=== services ==="
systemctl --user is-active sunshine 2>/dev/null || true
systemctl --user is-active rustdesk 2>/dev/null || true
systemctl --user is-active ydotoold 2>/dev/null || true
systemctl --user is-active wow-dictate-daemon 2>/dev/null || true
echo "=== ports (ssh / sunshine) ==="
ss -tlnp 2>/dev/null | grep -E ':(22|47984|47989|47990|48010)\s' || true
echo "=== local secrets ==="
if [[ -f "$REPO_ROOT/config/sunshine-web-password.txt" ]]; then
  echo "sunshine-web-password.txt present (chmod $(stat -c %a "$REPO_ROOT/config/sunshine-web-password.txt")) — do not commit"
else
  echo "no local sunshine password file"
fi
