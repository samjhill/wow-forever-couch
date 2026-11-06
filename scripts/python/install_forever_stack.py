#!/usr/bin/env python3
"""Install Forever couch addon stack (GitHub + CurseForge) into Interface/AddOns.

Cross-platform; used by Windows bootstrap and available to Linux scripts.
"""
from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path

# Allow running as scripts/python/install_forever_stack.py
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import curseforge_fetch  # noqa: E402
import unzip_addons  # noqa: E402

GITHUB = [
    (
        "ConsolePort-3.3.13.zip",
        "https://github.com/seblindfors/ConsolePort/releases/download/3.3.13/ConsolePort-3.3.13.zip",
    ),
    (
        "Immersion-1.4.61.zip",
        "https://github.com/seblindfors/Immersion/releases/download/1.4.61/Immersion-1.4.61.zip",
    ),
    (
        "forever-vo-v0.1.10-forever.zip",
        "https://github.com/quinn-dougherty/forever-vo/releases/download/v0.1.10/forever-vo-v0.1.10-forever.zip",
    ),
]

# ForeverVO voice packs
FVO_PACKS = [1705100, 1709884, 1729567, 1705094, 1729570, 1729514]

# QoL CurseForge projects: (id, optional name filter, optional filename preference)
QOL = [
    (988370, "", ""),  # Syndicator
    (914482, "", ""),  # Baganator
    (94855, "forever", ""),  # Leatrix Plus
    (100547, "", ""),  # Plater
    (1715510, "", ""),  # Lore Forever
    (1702832, "", ""),  # Fishing Log
    (1729017, "", ""),  # Loot Sparkles
    (1731463, "", ""),  # NodeSight
    (1757790, "", ""),  # Gather Radar
    (1703450, "", ""),  # AutoFeed (AutoFeed + AutoDrink macros)
    (1728015, "", ""),  # SmartRebuff (Forever buff monitor)
    (334372, "", "+v1.0"),  # Questie + QuestieDB (prefer DB bundle)
]


def sync_repo_addons(repo: Path, addons_dir: Path) -> None:
    for name in ("ConsolePortCouch", "CouchDictateRoute", "PlaterQuestPin"):
        src = repo / "addons" / name
        if not src.is_dir():
            print(f"skip missing repo addon: {name}")
            continue
        dest = addons_dir / name
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(src, dest)
        print(f"synced {name} → {dest}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--forever", required=True, help="Path to _forever_ client")
    ap.add_argument("--repo", required=True, help="Path to wow-forever-couch checkout")
    ap.add_argument("--staging", default="", help="Zip staging directory")
    ap.add_argument("--core-only", action="store_true", help="Skip CurseForge QoL set")
    args = ap.parse_args()

    forever = Path(args.forever)
    repo = Path(args.repo)
    addons = forever / "Interface" / "AddOns"
    addons.mkdir(parents=True, exist_ok=True)
    staging = Path(args.staging or (repo / "config" / "addons-staging"))
    staging.mkdir(parents=True, exist_ok=True)

    # Core GitHub zips
    core_zips: list[Path] = []
    for name, url in GITHUB:
        core_zips.append(curseforge_fetch.fetch_url(url, staging / name))
    # Clear previous ConsolePort/Immersion/ForeverVO trees
    for pattern in ("ConsolePort*", "Immersion", "ForeverVO", "ForeverVO_Data*"):
        for p in addons.glob(pattern):
            if p.is_dir():
                shutil.rmtree(p)
    for z in core_zips:
        unzip_addons.unzip_to(z, addons)

    for project in FVO_PACKS:
        z = curseforge_fetch.fetch_project(project, staging)
        unzip_addons.unzip_to(z, addons)

    if not args.core_only:
        for project, filt, prefer in QOL:
            try:
                z = curseforge_fetch.fetch_project(
                    project, staging, name_filter=filt, prefer=prefer
                )
                unzip_addons.unzip_to(z, addons, preserve_couch=True)
            except SystemExit as e:
                print(f"warn: project {project}: {e}", file=sys.stderr)

    sync_repo_addons(repo, addons)

    # Remove DialogKey forks if present
    for name in ("DialogKey_Numy", "DialogKey_Aeonzara", "DialogKey"):
        p = addons / name
        if p.exists():
            shutil.rmtree(p)
            print(f"removed {name}")

    print(f"Installed into {addons}")
    for name in sorted(os.listdir(addons)):
        print(name)


if __name__ == "__main__":
    main()
