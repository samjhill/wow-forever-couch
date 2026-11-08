#!/usr/bin/env bash
# Host libgnutls fails to initialize inside Proton (symbol mismatch with the
# Steam runtime). Battle.net setup then cannot fetch its versions file
# (BLZBNTBTS0000004A). Copy a matching GnuTLS stack from Steam Linux Runtime
# into the Proton library directories the loader searches first.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if [[ -z "${WOW_PROTON:-}" || ! -x "$WOW_PROTON" ]]; then
  WOW_PROTON="$(resolve_ge_proton)"
fi
if [[ -z "${WOW_PROTON:-}" || ! -x "$WOW_PROTON" ]]; then
  exit 0
fi

PROTON_DIR="$(cd "$(dirname "$WOW_PROTON")" && pwd)"
STEAM_ROOT="${HOME}/.local/share/Steam"
mapfile -t RT_LIBS < <(find "${STEAM_ROOT}/steamapps/common" -path '*/SteamLinuxRuntime_*/steamrt*_platform_*/files/lib/*/libgnutls.so.30.*' 2>/dev/null | sort -V || true)
if [[ ${#RT_LIBS[@]} -eq 0 ]]; then
  exit 0
fi

python3 - "${PROTON_DIR}" "${RT_LIBS[@]}" << 'PY'
import os, shutil, subprocess, sys
from pathlib import Path

proton_dir = Path(sys.argv[1])
runtime_libs = [Path(p) for p in sys.argv[2:]]

def needed(path: Path) -> list[str]:
    out = subprocess.check_output(["readelf", "-d", path], text=True, errors="replace")
    libs = []
    for line in out.splitlines():
        if "NEEDED" not in line or "[" not in line:
            continue
        libs.append(line.split("[", 1)[1].split("]", 1)[0])
    return libs

def soname(path: Path) -> str | None:
    out = subprocess.check_output(["readelf", "-d", path], text=True, errors="replace")
    for line in out.splitlines():
        if "SONAME" in line and "[" in line:
            return line.split("[", 1)[1].split("]", 1)[0]
    return None

copied = 0
for gnutls in runtime_libs:
    rt_dir = gnutls.parent
    arch = rt_dir.name
    dest = proton_dir / "files" / "lib" / arch
    if (dest / "libgnutls.so.30").exists():
        continue
    dest.mkdir(parents=True, exist_ok=True)
    queue = [gnutls.name]
    seen: set[str] = set()
    while queue:
        name = queue.pop()
        if name in seen:
            continue
        seen.add(name)
        src = rt_dir / name
        if not src.exists():
            matches = sorted(p for p in rt_dir.iterdir() if p.name.startswith(name + "."))
            if not matches:
                continue
            src = matches[-1]
            name = src.name
            if name in seen:
                continue
            seen.add(name)
        for lib in needed(src):
            if lib not in ("libc.so.6", "ld-linux.so.2", "ld-linux-x86-64.so.2"):
                queue.append(lib)
        target = dest / src.name
        if not target.exists():
            shutil.copy2(src, target)
            copied += 1
        link_name = soname(src)
        if link_name and not (dest / link_name).exists():
            os.symlink(src.name, dest / link_name)
if copied:
    print(f"Staged GnuTLS into {proton_dir} ({copied} libraries)")
PY
