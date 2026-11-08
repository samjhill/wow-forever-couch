#!/usr/bin/env bash
# Launch WoW Forever through Battle.net (GE-Proton). Extra args are forwarded.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

exec "${REPO_ROOT}/scripts/launch-battlenet-proton.sh" --game=WoWF "$@"
