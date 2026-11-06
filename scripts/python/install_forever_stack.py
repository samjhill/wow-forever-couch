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
import curseforge_projects  # noqa: E402
import unzip_addons  # noqa: E402

GITHUB = [
    (
        "Immersion-1.4.61.zip",
        "https://github.com/seblindfors/Immersion/releases/download/1.4.61/Immersion-1.4.61.zip",
    ),
]

def sync_repo_addons(repo: Path, addons_dir: Path) -> None:
    for name in ("CouchDictateRoute", "PlaterQuestPin"):
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

    # Immersion stays on the pinned GitHub zip; Spoken and its audio come from CurseForge.
    core_zips: list[Path] = []
    for name, url in GITHUB:
        core_zips.append(curseforge_fetch.fetch_url(url, staging / name))
    spoken = next(p for p in curseforge_projects.CORE if p.label == "Spoken")
    spoken_zips: list[Path] = []
    for project in (spoken, *curseforge_projects.VOICE_PACKS):
        spoken_zips.append(curseforge_fetch.fetch_project(project.project_id, staging))

    curseforge_projects.remove_replaced_addons(addons)
    for pattern in ("Immersion", "Spoken", "Spoken_*", "SpokenContributions", "SpokenQuestsAudio*", "SpokenPlacesAudio", "SpokenReadablesAudio", "SpokenBossesAudio"):
        for p in addons.glob(pattern):
            if p.is_dir():
                shutil.rmtree(p)
    for z in core_zips:
        unzip_addons.unzip_to(z, addons)
    for z in spoken_zips:
        unzip_addons.unzip_to(z, addons)

    if not args.core_only:
        for project in curseforge_projects.QOL:
            try:
                z = curseforge_fetch.fetch_project(
                    project.project_id,
                    staging,
                    name_filter=project.name_filter,
                    prefer=project.prefer,
                )
                unzip_addons.unzip_to(z, addons, preserve_couch=True)
            except SystemExit as e:
                print(f"warn: project {project.label}: {e}", file=sys.stderr)

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
