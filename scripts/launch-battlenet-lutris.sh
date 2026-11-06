#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
WRAPPER="${REPO_ROOT}/scripts/launch-battlenet-proton.sh"
EXE="$(find_battlenet_exe || true)"
if [[ -n "${EXE:-}" && -f "$EXE" ]]; then
  exec "$WRAPPER" "$@"
fi
echo "Battle.net not installed yet. From Desktop Mode run: $REPO_ROOT/scripts/install-battlenet-desktop.sh" >&2
exit 1
