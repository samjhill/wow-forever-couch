"""CurseForge projects installed into the Forever couch client.

Only files whose game versions include 1.60.x are selected. Staged addons
(BigWigs, GTFO, Talents Forever, Auctionator) are intentionally absent.
"""
from __future__ import annotations

import shutil
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class CurseForgeProject:
    project_id: int
    label: str
    name_filter: str = ""
    prefer: str = ""


# Pinned GitHub zips still bootstrap Immersion; the updater follows CurseForge.
# Spoken (addons) replaces Forever Voiceover. Blizzard's controller UI replaces ConsolePort.
CORE = [
    CurseForgeProject(257550, "Immersion"),
    CurseForgeProject(1700375, "Spoken"),
]

# English packs. The CurseForge "All" / "Spoken: English" projects are empty
# dependency stubs, so these are the addons that actually hold audio.
VOICE_PACKS = [
    CurseForgeProject(1660197, "Spoken Quests Audio Alliance"),
    CurseForgeProject(1660198, "Spoken Quests Audio Horde"),
    CurseForgeProject(1660199, "Spoken Quests Audio Shared"),
    CurseForgeProject(1660202, "Spoken Quests Audio Gossip"),
    CurseForgeProject(1636532, "Spoken Places Audio"),
    CurseForgeProject(1701520, "Spoken Readables Audio"),
    CurseForgeProject(1780747, "Spoken Bosses Audio"),
]

# Folders removed on install/sync. Globs are matched with Path.glob.
# SpokenQuests/SpokenZones/SpokenBooks are retired module names, not Spoken_Quests.
# Baganator is the bag UI; Syndicator is only its inventory backend.
# GatherRadar is the remembered herb/ore map; NodeSight stays.
REMOVED_GLOBS = (
    "ConsolePort",
    "ConsolePort_*",
    "ConsolePortCouch",
    "ForeverVO",
    "ForeverVO_*",
    "SpokenPlayer",
    "SpokenQuests",
    "SpokenZones",
    "SpokenBooks",
    "Baganator",
    "Syndicator",
    "GatherRadar",
)

QOL = [
    CurseForgeProject(94855, "Leatrix Plus", name_filter="forever"),
    CurseForgeProject(100547, "Plater"),
    CurseForgeProject(1715510, "Lore Forever"),
    CurseForgeProject(1702832, "The Fishing Log"),
    CurseForgeProject(1729017, "Forever Loot Sparkles"),
    CurseForgeProject(1731463, "NodeSight"),
    CurseForgeProject(1703450, "AutoFeed"),
    CurseForgeProject(1728015, "SmartRebuff"),
    # Questie 12.4+ no longer ships the database inside the addon zip.
    # Preferring "+v1.0" kept the October bundled file and skipped later map data.
    CurseForgeProject(334372, "Questie"),
    CurseForgeProject(1696795, "QuestieDB", name_filter="forever"),
]

# Repo-owned helpers. CurseForge zips must not replace these.
REPO_OWNED = ("CouchDictateRoute", "PlaterQuestPin", "CouchQuestArea")

# Addons the updater may install but should not force on.
DO_NOT_AUTO_ENABLE = ()


def update_projects() -> list[CurseForgeProject]:
    return [*CORE, *VOICE_PACKS, *QOL]


def remove_replaced_addons(addons_dir: Path) -> None:
    """Delete replaced addons: ConsolePort, Forever Voiceover, Baganator, and retired Spoken modules."""
    if not addons_dir.is_dir():
        return
    seen: set[Path] = set()
    for pattern in REMOVED_GLOBS:
        for path in addons_dir.glob(pattern):
            if not path.is_dir() or path in seen:
                continue
            seen.add(path)
            shutil.rmtree(path)
            print(f"removed {path.name}")
