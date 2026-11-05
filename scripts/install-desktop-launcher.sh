#!/usr/bin/env bash
# Install/update the Desktop + Applications menu launcher for bootstrap.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

SRC="${REPO_ROOT}/config/desktop/wow-forever-couch-bootstrap.desktop"
[[ -f "$SRC" ]] || { echo "missing $SRC" >&2; exit 2; }

python3 - "$REPO_ROOT" "$SRC" <<'PY'
import pathlib, sys
repo = pathlib.Path(sys.argv[1])
src = pathlib.Path(sys.argv[2])
lines = []
for line in src.read_text(encoding="utf-8").splitlines():
    if line.startswith("Exec="):
        # Prefer local bootstrap once cloned; still works offline after first install.
        lines.append(f"Exec={repo}/scripts/bootstrap-steamos.sh")
    else:
        lines.append(line)
text = "\n".join(lines) + "\n"
homes = [
    pathlib.Path.home() / "Desktop",
    pathlib.Path.home() / ".local/share/applications",
]
for dest in homes:
    dest.mkdir(parents=True, exist_ok=True)
    out = dest / "wow-forever-couch-setup.desktop"
    out.write_text(text, encoding="utf-8")
    out.chmod(out.stat().st_mode | 0o111)
    print(f"launcher → {out}")
print("Dolphin: right-click → Properties → Permissions → “Is executable”, then double-click → Trust and Launch")
PY
