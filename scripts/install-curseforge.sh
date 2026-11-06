#!/usr/bin/env bash
# Install Overwolf CurseForge (Flatpak) and grant access to the Forever client tree.
# Run from Desktop Mode to finish first-run UI (scan/add Forever game path).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

APP_ID="com.overwolf.curseforge"
LAUNCHER="${HOME}/.local/bin/curseforge-wow"

if ! command -v flatpak >/dev/null; then
  echo "flatpak required (Bazzite ships it)." >&2
  exit 2
fi

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
if flatpak info --user "$APP_ID" >/dev/null 2>&1; then
  echo "CurseForge already installed; updating…"
  flatpak update --user -y "$APP_ID" || true
else
  echo "Installing CurseForge from Flathub…"
  flatpak install --user -y flathub "$APP_ID"
fi

# Home + Proton prefix so Forever under Games/battlenet is writable
flatpak override --user \
  --filesystem=home \
  --filesystem="${WOW_PREFIX}" \
  --filesystem=xdg-download \
  "$APP_ID"

mkdir -p "$(dirname "$LAUNCHER")"
cat > "$LAUNCHER" <<'EOF'
#!/usr/bin/env bash
exec flatpak run com.overwolf.curseforge "$@"
EOF
chmod +x "$LAUNCHER"

mkdir -p "${WOW_COUCH_CONFIG}"
cat > "${WOW_COUCH_CONFIG}/curseforge-forever-path.txt" <<EOF
# In CurseForge: add / scan this Forever client folder (contains Wow.exe).
# Do not select Interface/AddOns.
${WOW_FOREVER}

Verify:
  test -f "${WOW_FOREVER}/Wow.exe" && echo wow_ok
  test -d "${WOW_ADDONS}" && echo addons_ok
EOF

echo
flatpak info --user "$APP_ID" | sed -n '1,20p'
echo
echo "Launcher: $LAUNCHER"
echo "Forever path note: ${WOW_COUCH_CONFIG}/curseforge-forever-path.txt"
echo
echo "Automatic Forever updates: ./scripts/install-curseforge-update-timer.sh"
echo "  (daily, about 04:00; not on Battle.net launch. The Flatpak app does not update in the background)"
echo
echo "First-run (Desktop Mode):"
echo "  1. steamos-session-select desktop   # if in Gaming Mode"
echo "  2. curseforge-wow"
echo "  3. World of Warcraft → add/scan Forever folder above"
echo "  4. Install only files tagged Forever / 1.60.x"
echo "  5. steamos-session-select gamescope # return to Gaming Mode when done"
