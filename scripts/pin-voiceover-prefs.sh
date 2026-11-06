#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Immersion TTS off. Spoken narrator style = voice only, so Immersion draws quests.
python3 "${REPO_ROOT}/scripts/python/pin_prefs.py" \
  --forever "$WOW_FOREVER" \
  --couch-config "$WOW_COUCH_CONFIG" \
  --voiceover
