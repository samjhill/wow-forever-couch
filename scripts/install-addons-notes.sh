#!/usr/bin/env bash
set -euo pipefail
echo "Find Forever AddOns directory:"
find "${HOME}/Games/battlenet/pfx" -type d -name AddOns 2>/dev/null || echo "(Forever not installed yet)"
echo
echo "Download Forever builds of ConsolePort + Immersion from CurseForge/Wago in a browser,"
echo "then unzip into the AddOns folder (one folder per addon)."
