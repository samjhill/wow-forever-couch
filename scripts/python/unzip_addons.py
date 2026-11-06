#!/usr/bin/env python3
"""Unzip addon archive(s) into a Forever Interface/AddOns directory."""
from __future__ import annotations

import argparse
import shutil
import tempfile
import zipfile
from pathlib import Path


PRESERVE = {
    "Immersion",
    "Spoken",
    "SpokenContributions",
    "CouchDictateRoute",
}


def is_preserved(name: str) -> bool:
    if name in PRESERVE:
        return True
    if name.startswith("Spoken_") or name.startswith("SpokenQuestsAudio") or name.startswith("SpokenPlacesAudio"):
        return True
    if name.startswith("SpokenReadablesAudio") or name.startswith("SpokenBossesAudio"):
        return True
    return False


def unzip_to(
    zip_path: Path,
    dest: Path,
    preserve_couch: bool = False,
    skip: set[str] | None = None,
) -> list[str]:
    installed: list[str] = []
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        with zipfile.ZipFile(zip_path) as zf:
            for info in zf.infolist():
                name = info.filename.replace("\\", "/")
                if not name or name.endswith("/"):
                    (root / name).mkdir(parents=True, exist_ok=True)
                    continue
                out = root / name
                out.parent.mkdir(parents=True, exist_ok=True)
                with zf.open(info) as src, open(out, "wb") as dst:
                    dst.write(src.read())

        # Descend single wrapper dir without toc
        entries = [p for p in root.iterdir()]
        extract_root = root
        skipped = skip or set()
        if len(entries) == 1 and entries[0].is_dir():
            if not list(entries[0].glob("*.toc")) and list(entries[0].rglob("*.toc")):
                extract_root = entries[0]

        # Flat zip (toc in root)
        flat_tocs = list(extract_root.glob("*.toc"))
        if flat_tocs and not any(p.is_dir() and list(p.glob("*.toc")) for p in extract_root.iterdir() if p.is_dir()):
            base = flat_tocs[0].stem
            if base in skipped or (preserve_couch and is_preserved(base)):
                print(f"skip preserved {base}")
            else:
                target = dest / base
                if target.exists():
                    shutil.rmtree(target)
                target.mkdir(parents=True)
                for item in extract_root.iterdir():
                    dest_item = target / item.name
                    if item.is_dir():
                        shutil.copytree(item, dest_item)
                    else:
                        shutil.copy2(item, dest_item)
                installed.append(base)
                print(f"installed {base} (flat)")
            return installed

        for d in extract_root.iterdir():
            if not d.is_dir():
                continue
            base = d.name
            if base in skipped or (preserve_couch and is_preserved(base)):
                print(f"skip preserved {base}")
                continue
            if not list(d.glob("*.toc")) and not list(d.rglob("*.toc")):
                continue
            target = dest / base
            if target.exists():
                shutil.rmtree(target)
            shutil.copytree(d, target)
            installed.append(base)
            print(f"installed {base}")
    return installed


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("zips", nargs="+", type=Path)
    ap.add_argument("--dest", required=True, type=Path)
    ap.add_argument("--preserve-couch", action="store_true")
    args = ap.parse_args()
    args.dest.mkdir(parents=True, exist_ok=True)
    for z in args.zips:
        unzip_to(z, args.dest, preserve_couch=args.preserve_couch)


if __name__ == "__main__":
    main()
