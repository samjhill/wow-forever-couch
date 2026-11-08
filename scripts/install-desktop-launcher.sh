#!/usr/bin/env bash
# Desktop + application-menu launchers: setup, Battle.net, and WoW Forever.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

SRC="${REPO_ROOT}/config/desktop/wow-forever-couch-bootstrap.desktop"
[[ -f "$SRC" ]] || { echo "missing $SRC" >&2; exit 2; }
chmod +x "${REPO_ROOT}/scripts/launch-battlenet-lutris.sh" \
  "${REPO_ROOT}/scripts/launch-forever.sh" 2>/dev/null || true

python3 - "$REPO_ROOT" "$SRC" <<'PY'
import pathlib, sys
repo = pathlib.Path(sys.argv[1])
src = pathlib.Path(sys.argv[2])
lines = []
for line in src.read_text(encoding="utf-8").splitlines():
    if line.startswith("Exec="):
        lines.append(f"Exec={repo}/scripts/bootstrap-steamos.sh")
    else:
        lines.append(line)
setup = "\n".join(lines) + "\n"

def entry(name, comment, exe):
    return (
        "[Desktop Entry]\n"
        "Type=Application\n"
        "Version=1.0\n"
        f"Name={name}\n"
        f"Comment={comment}\n"
        f"Exec={exe}\n"
        "Icon=applications-games\n"
        "Terminal=false\n"
        "StartupNotify=true\n"
        "Categories=Game;\n"
    )

files = {
    "wow-forever-couch-setup.desktop": setup,
    "battlenet.desktop": entry(
        "Battle.net",
        "Battle.net launcher (WoW Forever couch)",
        f"{repo}/scripts/launch-battlenet-lutris.sh",
    ),
    "wow-forever.desktop": entry(
        "WoW Forever",
        "Launch WoW Forever through Battle.net",
        f"{repo}/scripts/launch-forever.sh",
    ),
}
homes = [
    pathlib.Path.home() / "Desktop",
    pathlib.Path.home() / ".local/share/applications",
]
for dest in homes:
    dest.mkdir(parents=True, exist_ok=True)
    for name, text in files.items():
        out = dest / name
        out.write_text(text, encoding="utf-8")
        out.chmod(out.stat().st_mode | 0o111)
        print(f"launcher → {out}")
PY

# Plasma hides new Desktop icons until they are marked trusted.
if command -v gio >/dev/null 2>&1; then
  if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    plasma_pid="$(pgrep -n -u "$(id -u)" plasmashell || true)"
    if [[ -n "$plasma_pid" && -r "/proc/${plasma_pid}/environ" ]]; then
      while IFS= read -r -d '' kv; do
        case "$kv" in
          DBUS_SESSION_BUS_ADDRESS=*|DISPLAY=*|WAYLAND_DISPLAY=*|XDG_RUNTIME_DIR=*)
            export "$kv"
            ;;
        esac
      done < "/proc/${plasma_pid}/environ"
    fi
  fi
  for name in battlenet.desktop wow-forever.desktop wow-forever-couch-setup.desktop; do
    path="${HOME}/Desktop/${name}"
    if [[ -f "$path" ]]; then
      gio set "$path" metadata::trusted true || true
    fi
  done
fi
