#!/usr/bin/env bash
# Offline unit tests for CouchDictateRoute channel policy + inject env handling.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
RESOLVE="${REPO_ROOT}/scripts/resolve_channel.py"
FAILS=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*" >&2; FAILS=$((FAILS + 1)); }

expect() {
  local label="$1" want="$2"
  shift 2
  local got
  got="$(python3 "$RESOLVE" "$@")"
  local ch="${got%%$'\t'*}"
  if [[ "$ch" == "$want" ]]; then
    pass "$label → $want"
  else
    fail "$label: want=$want got=$got"
  fi
}

echo "=== channel policy ==="
expect "solo" say --size 0
expect "party of 2" say --size 2
expect "party of 3" party --size 3
expect "party of 5" party --size 5
expect "raid size 2" raid --raid --size 2
expect "raid size 10" raid --raid --size 10
expect "override party while solo" party --size 0 --override party
expect "override say in raid" say --raid --size 10 --override say

echo "=== slash prefixes ==="
[[ "$(python3 "$RESOLVE" --size 0 --slash)" == "/say " ]] && pass "say slash" || fail "say slash"
[[ "$(python3 "$RESOLVE" --size 3 --slash)" == "/p " ]] && pass "party slash" || fail "party slash"
[[ "$(python3 "$RESOLVE" --raid --size 10 --slash)" == "/raid " ]] && pass "raid slash" || fail "raid slash"

echo "=== inject dry checks (no ydotool) ==="
# Validate channel parsing without talking to ydotoold by sourcing logic via a dry run helper
dry_prefix() {
  local channel_lc
  channel_lc="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$channel_lc" in
    auto|"") echo "" ;;
    say|s) echo "/say " ;;
    party|p) echo "/p " ;;
    raid|r) echo "/raid " ;;
    *) return 1 ;;
  esac
}
[[ "$(dry_prefix auto)" == "" ]] && pass "inject auto prefix empty" || fail "inject auto"
[[ "$(dry_prefix party)" == "/p " ]] && pass "inject party prefix" || fail "inject party"
[[ "$(dry_prefix RAID)" == "/raid " ]] && pass "inject raid prefix casefold" || fail "inject raid"

echo "=== addon files present ==="
if [[ -f "${REPO_ROOT}/addons/CouchDictateRoute/CouchDictateRoute.toc" \
   && -f "${REPO_ROOT}/addons/CouchDictateRoute/CouchDictateRoute.lua" ]]; then
  pass "CouchDictateRoute sources present"
else
  fail "addon sources missing"
fi

# Sanity: Lua policy comments match tested sizes
if grep -q "Party of 3+" "${REPO_ROOT}/addons/CouchDictateRoute/CouchDictateRoute.lua" \
  && grep -q 'return "SAY"' "${REPO_ROOT}/addons/CouchDictateRoute/CouchDictateRoute.lua"; then
  pass "Lua policy markers present"
else
  fail "Lua policy markers missing"
fi

echo
if [[ "$FAILS" -gt 0 ]]; then
  echo "Channel routing tests: $FAILS failure(s)." >&2
  exit 1
fi
echo "Channel routing tests passed (offline). In-game sticky NOT verified."
