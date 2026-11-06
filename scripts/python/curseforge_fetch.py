#!/usr/bin/env python3
"""Fetch a CurseForge Forever (1.60.x) file into a staging directory.

Usage:
  curseforge_fetch.py --project ID [--name-filter forever] [--staging DIR]
  curseforge_fetch.py --url URL --out FILE

Prints the downloaded (or cached) file path on stdout.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.request
from pathlib import Path

UA = "wow-forever-couch"


def http_json(url: str) -> dict:
    req = urllib.request.Request(
        url, headers={"Accept": "application/json", "User-Agent": UA}
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def http_download(url: str, dest: Path) -> None:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    dest.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(req, timeout=300) as resp, open(dest, "wb") as out:
        while True:
            chunk = resp.read(1024 * 256)
            if not chunk:
                break
            out.write(chunk)


def pick_forever_file(files: list, name_filter: str = "", prefer: str = "") -> dict:
    def ok(f: dict) -> bool:
        gvs = [str(v) for v in (f.get("gameVersions") or [])]
        if not any(v.startswith("1.60") for v in gvs):
            return False
        if f.get("releaseType") not in (1, 2):
            return False
        if name_filter and name_filter.lower() not in (f.get("fileName") or "").lower():
            return False
        return True

    needle = prefer.lower()
    cand = [f for f in files if ok(f)]
    cand.sort(
        key=lambda f: (
            1 if needle and needle in (f.get("fileName") or "").lower() else 0,
            1 if f.get("releaseType") == 1 else 0,
            f.get("dateCreated") or "",
            f.get("fileLength") or 0,
        ),
        reverse=True,
    )
    if not cand:
        raise SystemExit("no Forever 1.60.x CurseForge file matched")
    return cand[0]


def forgecdn_url(file_id: int, file_name: str) -> str:
    hi, lo = file_id // 1000, file_id % 1000
    return f"https://edge.forgecdn.net/files/{hi}/{lo}/{file_name}"


def fetch_project(project: int, staging: Path, name_filter: str = "", prefer: str = "") -> Path:
    meta = http_json(
        f"https://www.curseforge.com/api/v1/mods/{project}/files?pageSize=40&sortField=1&sortOrder=desc"
    )
    f = pick_forever_file(meta.get("data") or [], name_filter=name_filter, prefer=prefer)
    file_id = int(f["id"])
    file_name = f["fileName"]
    file_len = int(f.get("fileLength") or 0)
    dest = staging / file_name
    if dest.exists() and file_len and dest.stat().st_size == file_len:
        print(f"cached {dest}", file=sys.stderr)
        return dest
    url = forgecdn_url(file_id, file_name)
    print(f"Downloading {file_name}", file=sys.stderr)
    http_download(url, dest)
    return dest


def fetch_url(url: str, out: Path) -> Path:
    if out.exists() and out.stat().st_size > 0:
        print(f"cached {out}", file=sys.stderr)
        return out
    print(f"Downloading {out.name}", file=sys.stderr)
    http_download(url, out)
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", type=int, help="CurseForge project id")
    ap.add_argument("--name-filter", default="", help="Substring required in fileName")
    ap.add_argument(
        "--prefer",
        default="",
        help="Prefer a filename containing this substring",
    )
    ap.add_argument(
        "--staging",
        default=os.environ.get("WOW_COUCH_STAGING", ""),
        help="Download directory",
    )
    ap.add_argument("--url", help="Direct zip URL")
    ap.add_argument("--out", help="Output path when using --url")
    args = ap.parse_args()

    if args.url:
        if not args.out:
            raise SystemExit("--out is required with --url")
        path = fetch_url(args.url, Path(args.out))
        print(path)
        return

    if not args.project:
        raise SystemExit("provide --project or --url")
    staging = Path(args.staging or Path.cwd())
    staging.mkdir(parents=True, exist_ok=True)
    path = fetch_project(args.project, staging, name_filter=args.name_filter, prefer=args.prefer)
    print(path)


if __name__ == "__main__":
    main()
