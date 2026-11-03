#!/usr/bin/env bash
# Back-compat alias → prefer-mic-source.sh
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/prefer-mic-source.sh" "$@"
