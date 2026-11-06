#!/usr/bin/env python3
"""Install newer Forever (1.60.x) CurseForge files into Interface/AddOns.

Skips while Wow.exe is running. Remembers the zip name and size so an
unchanged file is not extracted again. Does not replace repo-owned addons
and does not install the staged set (BigWigs, GTFO, Talents Forever, Auctionator).
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import curseforge_fetch  # noqa: E402
import curseforge_projects  # noqa: E402
import enable_addons  # noqa: E402
import unzip_addons  # noqa: E402

STATE_NAME = "curseforge-installed.json"


def game_running() -> bool:
    if sys.platform == "win32":
        try:
            out = subprocess.check_output(
                ["tasklist"], text=True, errors="replace", timeout=20
            )
        except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
            return False
        return "Wow.exe" in out or "WowClassic.exe" in out
    proc = Path("/proc")
    if not proc.is_dir():
        return False
    for cmd in proc.glob("*/cmdline"):
        try:
            raw = cmd.read_bytes().replace(b"\x00", b" ")
        except OSError:
            continue
        if b"Wow.exe" in raw or b"WowClassic.exe" in raw or b"WowForever" in raw:
            return True
    return False


def load_state(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    if not isinstance(data, dict):
        return {}
    return {str(k): str(v) for k, v in data.items()}


def save_state(path: Path, state: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp.replace(path)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--addons", required=True, type=Path)
    ap.add_argument("--staging", required=True, type=Path)
    ap.add_argument("--wtf-account", type=Path, default=None)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if game_running() and not args.dry_run:
        print("Forever is running — skip CurseForge addon update")
        return 0

    if not args.dry_run:
        args.addons.mkdir(parents=True, exist_ok=True)
    args.staging.mkdir(parents=True, exist_ok=True)
    state_path = args.staging / STATE_NAME
    state = load_state(state_path)
    skip = set(curseforge_projects.REPO_OWNED)
    enabled: list[str] = []
    failed = 0

    for project in curseforge_projects.update_projects():
        label = project.label
        try:
            zip_path = curseforge_fetch.fetch_project(
                project.project_id,
                args.staging,
                name_filter=project.name_filter,
                prefer=project.prefer,
            )
        except SystemExit as exc:
            failed += 1
            print(f"fail {label}: {exc}", file=sys.stderr)
            continue
        stamp = f"{zip_path.name}:{zip_path.stat().st_size}"
        key = str(project.project_id)
        if state.get(key) == stamp:
            print(f"current {label} ({zip_path.name})")
            continue
        if args.dry_run:
            print(f"would update {label} → {zip_path.name}")
            continue
        try:
            installed = unzip_addons.unzip_to(zip_path, args.addons, skip=skip)
        except (OSError, zipfile.BadZipFile) as exc:
            failed += 1
            print(f"fail {label}: {exc}", file=sys.stderr)
            continue
        state[key] = stamp
        enabled.extend(
            name
            for name in installed
            if name not in curseforge_projects.DO_NOT_AUTO_ENABLE
        )
        print(f"updated {label}: {', '.join(installed) or zip_path.name}")

    if not args.dry_run:
        save_state(state_path, state)
        if args.wtf_account and enabled:
            enable_addons.enable_names(args.wtf_account, enabled)

    if failed:
        print(f"{failed} CurseForge project(s) failed", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
