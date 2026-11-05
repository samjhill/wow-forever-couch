#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIRROR="${WOW_FOREVER_COUCH_REPO:-$HOME/Projects/wow-forever-couch}"
SUPPORT="$HOME/Library/Application Support/wow-forever-couch"
LABEL=com.samjhill.wow-forever-couch-live-setup

mkdir -p "$HOME/.cache/wow-forever-couch" "$HOME/Projects" "$SUPPORT"

if [[ ! -d "$MIRROR/.git" ]]; then
  git clone https://github.com/samjhill/wow-forever-couch.git "$MIRROR"
else
  git -C "$MIRROR" fetch origin
  git -C "$MIRROR" checkout main
  git -C "$MIRROR" pull --ff-only origin main || true
fi

# Keep mirror's scripts current from this checkout when installing from Documents
rsync -a \
  "$REPO_ROOT/scripts/auto-sync-live-setup.sh" \
  "$REPO_ROOT/scripts/snapshot-live-setup.sh" \
  "$REPO_ROOT/scripts/restore-live-setup.sh" \
  "$REPO_ROOT/scripts/lib.sh" \
  "$MIRROR/scripts/"
rsync -a "$REPO_ROOT/config/launchd/" "$MIRROR/config/launchd/"

cat > "$SUPPORT/run-auto-sync-live-setup.sh" <<WRAP
#!/bin/bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
REPO="${MIRROR}"
cd "\$REPO"
exec /bin/bash "\$REPO/scripts/auto-sync-live-setup.sh"
WRAP
chmod +x "$SUPPORT/run-auto-sync-live-setup.sh"

# Rewrite plist WorkingDirectory / env to this mirror
python3 - "$REPO_ROOT/config/launchd/${LABEL}.plist" "$HOME/Library/LaunchAgents/${LABEL}.plist" "$MIRROR" <<'PY'
import pathlib, sys
src, dst, mirror = map(pathlib.Path, sys.argv[1:])
text = src.read_text(encoding="utf-8")
# Ensure WorkingDirectory and WOW_FOREVER_COUCH_REPO match mirror
import re
text = re.sub(
    r"(<key>WorkingDirectory</key>\s*<string>)[^<]+",
    rf"\1{mirror}",
    text,
)
text = re.sub(
    r"(<key>WOW_FOREVER_COUCH_REPO</key>\s*<string>)[^<]+",
    rf"\1{mirror}",
    text,
)
dst.write_text(text, encoding="utf-8")
print(f"installed {dst}")
PY

uid=$(id -u)
launchctl bootout "gui/${uid}/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/${uid}" "$HOME/Library/LaunchAgents/${LABEL}.plist"
launchctl kickstart -k "gui/${uid}/${LABEL}"
echo "Autosave armed (every 4h). Logs: ~/.cache/wow-forever-couch/live-setup-sync.*.log"
