#!/usr/bin/env python3
"""Add (or refresh Steam Input for) a non-Steam Battle.net Forever shortcut.

Writes userdata/<id>/config/shortcuts.vdf and sets UseSteamControllerConfig=1
in localconfig.vdf. Does NOT set a Steam compatibility tool — the launch script
already runs GE-Proton.

Usage:
  add-steam-shortcut.py [--name NAME] [--exe PATH] [--start-dir DIR] [--steam-root DIR]
"""
from __future__ import annotations

import argparse
import re
import shutil
import struct
import sys
import time
import zlib
from pathlib import Path


DEFAULT_NAME = "Battle.net (WoW Forever)"


def crc32_app_id(exe: str, name: str) -> int:
    """Steam non-Steam AppID: CRC32(exe + name) with high bit set."""
    data = (exe + name).encode("utf-8")
    return (zlib.crc32(data) & 0xFFFFFFFF) | 0x80000000


def signed_app_id(app_id: int) -> int:
    app_id &= 0xFFFFFFFF
    if app_id >= 0x80000000:
        return app_id - 0x100000000
    return app_id


def find_steam_roots(explicit: str | None) -> list[Path]:
    if explicit:
        return [Path(explicit).expanduser()]
    home = Path.home()
    candidates = [
        home / ".local/share/Steam",
        home / ".steam/steam",
        home / ".steam/root",
    ]
    seen: set[Path] = set()
    out: list[Path] = []
    for c in candidates:
        try:
            resolved = c.resolve()
        except OSError:
            continue
        if resolved in seen or not resolved.is_dir():
            continue
        seen.add(resolved)
        out.append(resolved)
    return out


def userdata_dirs(steam_root: Path) -> list[Path]:
    ud = steam_root / "userdata"
    if not ud.is_dir():
        return []
    dirs = []
    for child in sorted(ud.iterdir()):
        if not child.is_dir() or not child.name.isdigit():
            continue
        if child.name == "0":
            continue
        dirs.append(child)
    return dirs


def backup(path: Path) -> Path | None:
    if not path.exists():
        return None
    stamp = time.strftime("%Y%m%d-%H%M%S")
    dest = path.with_name(f"{path.name}.bak-{stamp}")
    shutil.copy2(path, dest)
    return dest


def _read_cstring(data: bytes, i: int) -> tuple[str, int]:
    end = data.index(b"\x00", i)
    return data[i:end].decode("utf-8", errors="replace"), end + 1


def parse_shortcuts(data: bytes) -> list[dict]:
    """Parse binary shortcuts.vdf into a list of entry dicts."""
    if not data:
        return []

    def parse_object(start: int) -> tuple[dict, int]:
        obj: dict = {}
        i = start
        while i < len(data):
            typ = data[i]
            i += 1
            if typ == 0x08:
                return obj, i
            key, i = _read_cstring(data, i)
            if typ == 0x00:
                nested, i = parse_object(i)
                if key == "tags":
                    tags = []
                    for k in sorted(nested.keys(), key=lambda x: int(x) if str(x).isdigit() else 9999):
                        if isinstance(nested[k], str):
                            tags.append(nested[k])
                    obj["tags"] = tags
                else:
                    obj[key] = nested
            elif typ == 0x01:
                val, i = _read_cstring(data, i)
                obj[key] = val
            elif typ == 0x02:
                # Steam stores appid as uint32 bits in this slot
                val = struct.unpack_from("<I", data, i)[0]
                i += 4
                obj[key] = val
            elif typ == 0x07:
                val = struct.unpack_from("<Q", data, i)[0]
                i += 8
                obj[key] = val
            else:
                raise ValueError(f"unknown vdf type {typ:#x} at offset {i}")
        return obj, i

    i = 0
    if data[0] == 0x00:
        name, i = _read_cstring(data, 1)
        if name != "shortcuts":
            i = 0
    root, _ = parse_object(i)
    entries: list[dict] = []
    for k in sorted(root.keys(), key=lambda x: int(x) if str(x).isdigit() else 9999):
        if str(k).isdigit() and isinstance(root[k], dict):
            entries.append(root[k])
    return entries


def build_shortcuts(entries: list[dict]) -> bytes:
    out = bytearray()

    def write_string(key: str, val: str) -> None:
        out.append(0x01)
        out.extend(key.encode("utf-8") + b"\x00")
        out.extend(val.encode("utf-8") + b"\x00")

    def write_u32(key: str, val: int) -> None:
        out.append(0x02)
        out.extend(key.encode("utf-8") + b"\x00")
        out.extend(struct.pack("<I", val & 0xFFFFFFFF))

    out.append(0x00)
    out.extend(b"shortcuts\x00")

    for idx, e in enumerate(entries):
        out.append(0x00)
        out.extend(f"{idx}\x00".encode("utf-8"))

        write_u32("appid", int(e.get("appid", 0)))
        write_string("AppName", str(e.get("AppName", "")))
        write_string("Exe", str(e.get("Exe", "")))
        write_string("StartDir", str(e.get("StartDir", "")))
        write_string("icon", str(e.get("icon", "")))
        write_string("ShortcutPath", str(e.get("ShortcutPath", "")))
        write_string("LaunchOptions", str(e.get("LaunchOptions", "")))
        write_u32("IsHidden", int(e.get("IsHidden", 0)))
        write_u32("AllowDesktopConfig", int(e.get("AllowDesktopConfig", 1)))
        write_u32("AllowOverlay", int(e.get("AllowOverlay", 1)))
        write_u32("OpenVR", int(e.get("OpenVR", 0)))
        write_u32("Devkit", int(e.get("Devkit", 0)))
        write_string("DevkitGameID", str(e.get("DevkitGameID", "")))
        write_u32("DevkitOverrideAppID", int(e.get("DevkitOverrideAppID", 0)))
        write_u32("LastPlayTime", int(e.get("LastPlayTime", 0)))
        write_string("FlatpakAppID", str(e.get("FlatpakAppID", "")))

        out.append(0x00)
        out.extend(b"tags\x00")
        for ti, tag in enumerate(e.get("tags") or []):
            write_string(str(ti), str(tag))
        out.append(0x08)

        out.append(0x08)

    out.append(0x08)
    return bytes(out)


def quoted_path(path: Path) -> str:
    return f'"{path}"'


def ensure_shortcut(
    shortcuts_path: Path,
    name: str,
    exe_quoted: str,
    start_dir_quoted: str,
) -> tuple[int, bool]:
    """Return (app_id, created_new). If name exists, leave shortcuts.vdf alone."""
    app_id = crc32_app_id(exe_quoted, name)
    if shortcuts_path.exists() and shortcuts_path.stat().st_size > 0:
        try:
            entries = parse_shortcuts(shortcuts_path.read_bytes())
        except Exception as exc:  # noqa: BLE001
            print(f"warning: could not parse {shortcuts_path}: {exc}", file=sys.stderr)
            entries = []
    else:
        entries = []

    for e in entries:
        if e.get("AppName") == name:
            existing_id = int(e.get("appid", 0)) & 0xFFFFFFFF
            return existing_id or app_id, False

    entries.append(
        {
            "appid": app_id,
            "AppName": name,
            "Exe": exe_quoted,
            "StartDir": start_dir_quoted,
            "icon": "",
            "ShortcutPath": "",
            "LaunchOptions": "",
            "IsHidden": 0,
            "AllowDesktopConfig": 1,
            "AllowOverlay": 1,
            "OpenVR": 0,
            "Devkit": 0,
            "DevkitGameID": "",
            "DevkitOverrideAppID": 0,
            "LastPlayTime": 0,
            "FlatpakAppID": "",
            "tags": [],
        }
    )
    backup(shortcuts_path)
    shortcuts_path.parent.mkdir(parents=True, exist_ok=True)
    shortcuts_path.write_bytes(build_shortcuts(entries))
    return app_id, True


def ensure_steam_input(localconfig: Path, app_id: int) -> bool:
    """Set UseSteamControllerConfig=1 for signed app id. Returns True if changed."""
    signed = str(signed_app_id(app_id))
    if not localconfig.exists():
        print(f"warning: missing {localconfig} — skip Steam Input flag", file=sys.stderr)
        return False

    text = localconfig.read_text(encoding="utf-8", errors="replace")
    block_re = re.compile(
        rf'("{re.escape(signed)}"\s*\{{)(.*?)(\n\s*\}})',
        re.DOTALL,
    )
    m = block_re.search(text)
    if m:
        body = m.group(2)
        if re.search(r'"UseSteamControllerConfig"\s+"1"', body):
            return False
        if re.search(r'"UseSteamControllerConfig"\s+"\d+"', body):
            new_body = re.sub(
                r'"UseSteamControllerConfig"\s+"\d+"',
                '"UseSteamControllerConfig"\t\t"1"',
                body,
                count=1,
            )
        else:
            new_body = body.rstrip() + '\n\t\t\t\t\t"UseSteamControllerConfig"\t\t"1"\n'
        new_text = text[: m.start()] + m.group(1) + new_body + m.group(3) + text[m.end() :]
        backup(localconfig)
        localconfig.write_text(new_text, encoding="utf-8")
        return True

    apps_re = re.compile(r'("apps"\s*\{)', re.IGNORECASE)
    am = apps_re.search(text)
    insert = (
        f'\n\t\t\t\t"{signed}"\n'
        f"\t\t\t\t{{\n"
        f'\t\t\t\t\t"UseSteamControllerConfig"\t\t"1"\n'
        f"\t\t\t\t}}\n"
    )
    if am:
        pos = am.end()
        new_text = text[:pos] + insert + text[pos:]
        backup(localconfig)
        localconfig.write_text(new_text, encoding="utf-8")
        return True

    print(
        f"warning: no apps section in {localconfig} — could not set Steam Input",
        file=sys.stderr,
    )
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--name", default=DEFAULT_NAME)
    parser.add_argument("--exe", required=True, help="Path to launch script")
    parser.add_argument("--start-dir", default="", help="Start directory")
    parser.add_argument("--steam-root", default="", help="Override Steam install root")
    args = parser.parse_args()

    exe_path = Path(args.exe).expanduser().resolve()
    if not exe_path.is_file():
        print(f"exe not found: {exe_path}", file=sys.stderr)
        return 2
    start_dir = Path(args.start_dir).expanduser().resolve() if args.start_dir else exe_path.parent
    exe_quoted = quoted_path(exe_path)
    start_quoted = quoted_path(start_dir)

    roots = find_steam_roots(args.steam_root or None)
    if not roots:
        print("No Steam install found under ~/.local/share/Steam or ~/.steam.", file=sys.stderr)
        return 2

    any_userdata = False
    wrote = False
    for root in roots:
        for ud in userdata_dirs(root):
            any_userdata = True
            cfg = ud / "config"
            cfg.mkdir(parents=True, exist_ok=True)
            shortcuts = cfg / "shortcuts.vdf"
            localconfig = cfg / "localconfig.vdf"
            app_id, created = ensure_shortcut(shortcuts, args.name, exe_quoted, start_quoted)
            si = ensure_steam_input(localconfig, app_id)
            signed = signed_app_id(app_id)
            print(
                f"{ud}: appid={app_id} signed={signed} "
                f"shortcut={'created' if created else 'exists'} steam_input={'set' if si else 'ok'}"
            )
            wrote = True

    if not any_userdata:
        print(
            "No Steam userdata yet. Sign into Steam once (Desktop Mode), then re-run:\n"
            "  scripts/add-steam-shortcut.sh",
            file=sys.stderr,
        )
        return 3

    if not wrote:
        return 2
    print(f"Shortcut ready: {args.name}")
    print(f"  Exe: {exe_quoted}")
    print("Do not force Steam Proton on this shortcut (launch script uses GE-Proton).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
