#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
STAGING="${WOW_COUCH_CONFIG}/addons-staging"
mkdir -p "$STAGING" "$WOW_ADDONS"

# Immersion (pinned GitHub zip) + Spoken and its English audio packs.
# Removes ConsolePort and Forever Voiceover. Skips the QoL set.
python3 "${REPO_ROOT}/scripts/python/install_forever_stack.py" \
  --forever "$WOW_FOREVER" \
  --repo "$REPO_ROOT" \
  --staging "$STAGING" \
  --core-only
