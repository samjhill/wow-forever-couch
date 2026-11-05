#!/usr/bin/env python3
"""Pin Immersion/ForeverVO prefs and Forever Config.wtf (cross-platform)."""
from __future__ import annotations

import argparse
import re
from datetime import datetime, timezone
from pathlib import Path


def pin_config_set(cfg: Path, key: str, val: str) -> None:
    cfg.parent.mkdir(parents=True, exist_ok=True)
    text = cfg.read_text(encoding="utf-8", errors="replace") if cfg.exists() else ""
    pat = re.compile(rf'(?im)^SET\s+{re.escape(key)}\s+".*"\s*$')
    line = f'SET {key} "{val}"'
    if pat.search(text):
        text = pat.sub(line, text, count=1)
    else:
        if text and not text.endswith("\n"):
            text += "\n"
        text += line + "\n"
    cfg.write_text(text, encoding="utf-8")
    print(f"pinned {key}={val}")


def pin_graphics(forever: Path, couch_config: Path, force: bool = False) -> None:
    cfg = forever / "WTF" / "Config.wtf"
    flag = couch_config / "forever-graphics-pinned"
    pin_config_set(cfg, "GxApi", "D3D11")
    pin_config_set(cfg, "vsync", "1")
    pin_config_set(cfg, "maxFPS", "60")
    pin_config_set(cfg, "GamePadCursorAutoEnable", "0")
    pin_config_set(cfg, "GamePadCursorCenteredEmulation", "0")
    pin_config_set(cfg, "GamePadCursorLeftClick", "none")
    pin_config_set(cfg, "GamePadCursorRightClick", "none")
    if force or not flag.exists():
        pin_config_set(cfg, "graphicsQuality", "3")
        pin_config_set(cfg, "RAIDgraphicsQuality", "3")
        flag.write_text(datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ") + "\n", encoding="utf-8")
        print(f"pinned quality tier 3 ({flag})")
    else:
        print(f"quality tier already pinned ({flag})")


def pin_voiceover(forever: Path) -> None:
    wtf = forever / "WTF" / "Account"
    if not wtf.is_dir():
        print(f"No WTF/Account yet under {wtf}")
        return
    immersion = list(wtf.glob("*/SavedVariables/Immersion.lua"))
    fvo = list(wtf.glob("*/SavedVariables/ForeverVO.lua"))
    for path in immersion:
        text = path.read_text(encoding="utf-8", errors="replace")
        orig = text
        if re.search(r"\bImmersionSetup\s*=", text):
            if re.search(r"\bttsenabled\s*=", text):
                text = re.sub(r"(\bttsenabled\s*=\s*)[^,\n}]+", r"\1false", text, count=1)
            else:
                text = re.sub(
                    r"(\bImmersionSetup\s*=\s*\{)",
                    r"\1\n\tttsenabled = false,",
                    text,
                    count=1,
                )
        else:
            text = "ImmersionSetup = {\n\tttsenabled = false,\n}\n" + text
        if text != orig:
            path.write_text(text, encoding="utf-8")
            print(f"pinned Immersion TTS off: {path}")
        else:
            print(f"already pinned Immersion: {path}")
    for path in fvo:
        text = path.read_text(encoding="utf-8", errors="replace")
        orig = text
        if re.search(r"\bForeverVODB\s*=", text):

            def set_flag(blob: str, key: str, value: str) -> str:
                pat = rf'(\["{key}"\]|{key})\s*=\s*[^,\n}}]+'
                if re.search(pat, blob):
                    return re.sub(pat, rf"\1 = {value}", blob)
                return re.sub(
                    r"(\bForeverVODB\s*=\s*\{)",
                    rf"\1\n\t{key} = {value},",
                    blob,
                    count=1,
                )

            for key in ("playAccept", "playComplete", "playGreeting", "playGossip"):
                text = set_flag(text, key, "true")
            text = set_flag(text, "showPanel", "false")
        if text != orig:
            path.write_text(text, encoding="utf-8")
            print(f"pinned ForeverVO audio on + showPanel off: {path}")
        else:
            print(f"ForeverVO prefs OK: {path}")
    if not immersion:
        print("No Immersion.lua yet (enable Immersion in-game once, then re-run).")
    if not fvo:
        print("No ForeverVO.lua yet (defaults usually OK).")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--forever", required=True)
    ap.add_argument("--couch-config", required=True)
    ap.add_argument("--voiceover", action="store_true")
    ap.add_argument("--graphics", action="store_true")
    ap.add_argument("--force-graphics", action="store_true")
    args = ap.parse_args()
    forever = Path(args.forever)
    couch = Path(args.couch_config)
    if args.voiceover:
        pin_voiceover(forever)
    if args.graphics:
        pin_graphics(forever, couch, force=args.force_graphics)


if __name__ == "__main__":
    main()
