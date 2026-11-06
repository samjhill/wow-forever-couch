#!/usr/bin/env python3
"""Pin Immersion/Spoken prefs and Forever Config.wtf (cross-platform)."""
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


SPOKEN_SEED = """SpokenSettings = {
\t["global"] = {
\t\t["NewCharacterProfile"] = "Couch",
\t},
\t["profiles"] = {
\t\t["Couch"] = {
\t\t\t["Frame"] = {
\t\t\t\t["Style"] = "none",
\t\t\t},
\t\t},
\t},
}
"""


def _match_brace(text: str, open_idx: int) -> int | None:
    depth = 0
    i = open_idx
    quote = ""
    while i < len(text):
        c = text[i]
        if quote:
            if c == "\\":
                i += 2
                continue
            if c == quote:
                quote = ""
            i += 1
            continue
        if c in "\"'":
            quote = c
            i += 1
            continue
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return None


def _set_frame_style(body: str) -> str:
    """Force narrator Style = \"none\" (voice only) inside one Frame table body."""
    if re.search(r'(\["Style"\]|\bStyle)\s*=', body):
        return re.sub(
            r'(\["Style"\]|\bStyle)\s*=\s*(?:"[^"]*"|\'[^\']*\')',
            r'\1 = "none"',
            body,
        )
    return '\n\t\t\t["Style"] = "none",' + body


_FRAME_BLOCK = '\n\t\t\t["Frame"] = {\n\t\t\t\t["Style"] = "none",\n\t\t\t},'


def _profiles_span(text: str) -> tuple[int, int] | None:
    match = re.search(r'(?:\["profiles"\]|\bprofiles)\s*=\s*\{', text)
    if not match:
        return None
    open_idx = match.end() - 1
    close_idx = _match_brace(text, open_idx)
    if close_idx is None:
        return None
    return open_idx, close_idx


def _inject_voice_only_frames(text: str) -> str:
    """Set Style on every Frame table, and add one to profiles that have none."""
    frames = list(re.finditer(r'(?:\["Frame"\]|\bFrame)\s*=\s*\{', text))
    for match in reversed(frames):
        open_idx = match.end() - 1
        close_idx = _match_brace(text, open_idx)
        if close_idx is None:
            continue
        body = text[open_idx + 1 : close_idx]
        text = text[: open_idx + 1] + _set_frame_style(body) + text[close_idx:]

    span = _profiles_span(text)
    if span is None:
        return text
    open_idx, close_idx = span
    inner = text[open_idx + 1 : close_idx]
    inserts: list[tuple[int, str]] = []
    i = 0
    depth = 0
    quote = ""
    while i < len(inner):
        c = inner[i]
        if quote:
            if c == "\\":
                i += 2
                continue
            if c == quote:
                quote = ""
            i += 1
            continue
        if c in "\"'":
            quote = c
            i += 1
            continue
        if c == "{":
            depth += 1
            if depth == 1:
                body_end = _match_brace(inner, i)
                if body_end is None:
                    break
                body = inner[i + 1 : body_end]
                if not re.search(r'(?:\["Frame"\]|\bFrame)\s*=\s*\{', body):
                    inserts.append((i + 1, _FRAME_BLOCK))
                i = body_end + 1
                depth = 0
                continue
        elif c == "}":
            depth = max(0, depth - 1)
        i += 1
    for at, block in reversed(inserts):
        inner = inner[:at] + block + inner[at:]
    return text[: open_idx + 1] + inner + text[close_idx:]


def pin_spoken_text(text: str) -> str:
    """Immersion draws quests; Spoken plays audio with no narrator window."""
    if not re.search(r"\bSpokenSettings\s*=", text):
        extra = text if (not text or text.endswith("\n")) else text + "\n"
        return SPOKEN_SEED + extra

    text = _inject_voice_only_frames(text)

    if not re.search(r'\["Couch"\]\s*=', text):
        text = re.sub(
            r'(\["profiles"\]|\bprofiles)\s*=\s*\{',
            r'\1 = {\n\t\t["Couch"] = {\n\t\t\t["Frame"] = {\n\t\t\t\t["Style"] = "none",\n\t\t\t},\n\t\t},',
            text,
            count=1,
        )
    if re.search(r'\["NewCharacterProfile"\]\s*=', text):
        text = re.sub(
            r'(\["NewCharacterProfile"\]\s*=\s*)(?:"[^"]*"|\'[^\']*\')',
            r'\1"Couch"',
            text,
            count=1,
        )
    elif re.search(r'\["global"\]\s*=\s*\{', text):
        text = re.sub(
            r'(\["global"\]\s*=\s*\{)',
            r'\1\n\t\t["NewCharacterProfile"] = "Couch",',
            text,
            count=1,
        )
    else:
        text = re.sub(
            r'(\bSpokenSettings\s*=\s*\{)',
            r'\1\n\t["global"] = {\n\t\t["NewCharacterProfile"] = "Couch",\n\t},',
            text,
            count=1,
        )
    return text


def _pin_immersion_text(text: str) -> str:
    if re.search(r"\bImmersionSetup\s*=", text):
        if re.search(r"\bttsenabled\s*=", text):
            return re.sub(r"(\bttsenabled\s*=\s*)[^,\n}]+", r"\1false", text, count=1)
        return re.sub(
            r"(\bImmersionSetup\s*=\s*\{)",
            r"\1\n\tttsenabled = false,",
            text,
            count=1,
        )
    return "ImmersionSetup = {\n\tttsenabled = false,\n}\n" + text


def pin_voiceover(forever: Path) -> None:
    wtf = forever / "WTF" / "Account"
    if not wtf.is_dir():
        print(f"No WTF/Account yet under {wtf}")
        return
    immersion = list(wtf.glob("*/SavedVariables/Immersion.lua"))
    spoken = list(wtf.glob("*/SavedVariables/Spoken.lua"))
    accounts = [p for p in wtf.iterdir() if p.is_dir() and p.name != "SavedVariables"]
    for path in immersion:
        text = path.read_text(encoding="utf-8", errors="replace")
        updated = _pin_immersion_text(text)
        if updated != text:
            path.write_text(updated, encoding="utf-8")
            print(f"pinned Immersion TTS off: {path}")
        else:
            print(f"already pinned Immersion: {path}")
    for acct in accounts:
        sv = acct / "SavedVariables"
        sv.mkdir(parents=True, exist_ok=True)
        path = sv / "Spoken.lua"
        if path not in spoken:
            spoken.append(path)
    for path in spoken:
        path.parent.mkdir(parents=True, exist_ok=True)
        text = path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""
        updated = pin_spoken_text(text)
        if updated != text:
            path.write_text(updated, encoding="utf-8")
            print(f"pinned Spoken voice only (Immersion draws quests): {path}")
        else:
            print(f"Spoken prefs OK (voice only): {path}")
    if not immersion:
        print("No Immersion.lua yet (enable Immersion in-game once, then re-run).")
    print("In-game: /sp options → Narrator Style → Voice Only. Quit Forever fully if it was open.")


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
