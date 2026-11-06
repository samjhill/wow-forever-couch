#!/usr/bin/env python3
"""Enable/disable Forever AddOns.txt entries under WTF/Account."""
from __future__ import annotations

import argparse
from pathlib import Path

DEFAULT_ENABLE = [
    "Immersion",
    "Spoken", "Spoken_Quests", "Spoken_Places", "Spoken_Readables", "Spoken_Bosses",
    "SpokenContributions",
    "SpokenQuestsAudioAlliance", "SpokenQuestsAudioHorde", "SpokenQuestsAudioShared",
    "SpokenQuestsAudioGossip",
    "SpokenPlacesAudio", "SpokenReadablesAudio", "SpokenBossesAudio",
    "CouchDictateRoute",
    "Leatrix_Plus", "Plater", "PlaterQuestPin",
    "LoreForever", "LoreForever_Voice_Default", "LoreForever_Voice_Default_Alliance",
    "LoreForever_Voice_Default_Horde",
    "TheFishingLog", "ForeverLootSparkles", "NodeSight",
    "AutoFeed", "SmartRebuff",
    "QuestieDB", "Questie",
]

DEFAULT_DISABLE = [
    "DialogKey_Numy", "DialogKey_Aeonzara", "DialogKey",
    "SelfBuffs", "CouchBuffReminder",
    "ConsolePort", "ConsolePort_Bar", "ConsolePort_Config", "ConsolePort_Cursor",
    "ConsolePort_Menu", "ConsolePort_Rings", "ConsolePort_Target", "ConsolePort_World",
    "ConsolePort_Keyboard", "ConsolePortCouch",
    "ForeverVO",
    "ForeverVO_Data_Classic_Quests", "ForeverVO_Data_Classic_Endgame", "ForeverVO_Data_Classic_Gossip",
    "ForeverVO_Data_Forever_Quests", "ForeverVO_Data_Forever_Gossip", "ForeverVO_Data_Books",
    "SpokenPlayer", "SpokenQuests", "SpokenZones", "SpokenBooks",
    "Baganator", "Syndicator",
    "GatherRadar",
]


def sync_file(path: Path, enable: list[str], disable: list[str]) -> None:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines() if path.exists() else []
    state: dict[str, str] = {}
    order: list[str] = []
    for line in lines:
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        if ": " in s:
            name, val = s.split(": ", 1)
        elif s.startswith("enable "):
            name, val = s[7:].strip(), "enabled"
        elif s.startswith("disable "):
            name, val = s[8:].strip(), "disabled"
        else:
            continue
        name = name.strip()
        val = val.strip().lower()
        if name not in state:
            order.append(name)
        state[name] = "enabled" if val.startswith("enable") else "disabled"
    for name in enable:
        if name not in state:
            order.append(name)
        state[name] = "enabled"
    for name in disable:
        if name not in state:
            order.append(name)
        state[name] = "disabled"
    out = [f"{n}: {state[n]}" for n in order]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(out) + ("\n" if out else ""), encoding="utf-8")
    print(
        f"updated {path} (enabled={sum(1 for v in state.values() if v == 'enabled')}, "
        f"disabled={sum(1 for v in state.values() if v == 'disabled')})"
    )


def enable_names(root: Path, names: list[str]) -> None:
    """Mark addon folders enabled. Leaves every other AddOns.txt row alone."""
    if not root.is_dir() or not names:
        return
    files = list(root.glob("*/AddOns.txt")) + list(root.glob("*/*/AddOns.txt")) + list(
        root.glob("*/*/*/AddOns.txt")
    )
    for path in files:
        if "SavedVariables" in path.parts:
            continue
        sync_file(path, names, [])


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--wtf-account", required=True, type=Path)
    ap.add_argument("--enable", nargs="*", default=DEFAULT_ENABLE)
    ap.add_argument("--disable", nargs="*", default=DEFAULT_DISABLE)
    args = ap.parse_args()
    root = args.wtf_account
    if not root.is_dir():
        print(f"No WTF/Account yet at {root}. Log in / create a character, then re-run.")
        return
    files = list(root.glob("*/AddOns.txt")) + list(root.glob("*/*/AddOns.txt")) + list(
        root.glob("*/*/*/AddOns.txt")
    )
    for f in files:
        if "SavedVariables" in str(f):
            continue
        sync_file(f, args.enable, args.disable)
    for acct in root.iterdir():
        if not acct.is_dir() or acct.name == "SavedVariables":
            continue
        seed = acct / "AddOns.txt"
        if not seed.exists():
            sync_file(seed, args.enable, args.disable)
    sv = root / "SavedVariables" / "AddOns.txt"
    if sv.exists():
        sv.unlink()


if __name__ == "__main__":
    main()
