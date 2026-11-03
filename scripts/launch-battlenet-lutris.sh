#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
WRAPPER="${REPO_ROOT}/scripts/launch-battlenet-proton.sh"
if find "${WOW_PREFIX}/pfx" -name 'Battle.net.exe' 2>/dev/null | grep -q .; then
  exec "$WRAPPER"
fi
echo "Battle.net not installed yet. From Desktop Mode run: $REPO_ROOT/scripts/install-battlenet-desktop.sh" >&2
exit 1
