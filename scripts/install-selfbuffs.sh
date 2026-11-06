#!/usr/bin/env bash
# Deprecated: SelfBuffs + CouchBuffReminder were replaced by SmartRebuff.
# shellcheck source=install-smartrebuff.sh
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install-smartrebuff.sh" "$@"
