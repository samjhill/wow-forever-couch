"""CurseForge projects installed into the Forever couch client.

Only files whose game versions include 1.60.x are selected. Staged addons
(BigWigs, GTFO, Talents Forever, Auctionator) are intentionally absent.
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class CurseForgeProject:
    project_id: int
    label: str
    name_filter: str = ""
    prefer: str = ""


# Pinned GitHub zips still bootstrap these; the updater follows CurseForge.
CORE = [
    CurseForgeProject(91376, "ConsolePort"),
    CurseForgeProject(257550, "Immersion"),
    CurseForgeProject(1705010, "ForeverVO"),
]

VOICE_PACKS = [
    CurseForgeProject(1705100, "ForeverVO Classic Quests"),
    CurseForgeProject(1709884, "ForeverVO Classic Endgame"),
    CurseForgeProject(1729567, "ForeverVO Classic Gossip"),
    CurseForgeProject(1705094, "ForeverVO Forever Quests"),
    CurseForgeProject(1729570, "ForeverVO Forever Gossip"),
    CurseForgeProject(1729514, "ForeverVO Books"),
]

QOL = [
    CurseForgeProject(988370, "Syndicator"),
    CurseForgeProject(914482, "Baganator"),
    CurseForgeProject(94855, "Leatrix Plus", name_filter="forever"),
    CurseForgeProject(100547, "Plater"),
    CurseForgeProject(1715510, "Lore Forever"),
    CurseForgeProject(1702832, "The Fishing Log"),
    CurseForgeProject(1729017, "Forever Loot Sparkles"),
    CurseForgeProject(1731463, "NodeSight"),
    CurseForgeProject(1757790, "Gather Radar"),
    CurseForgeProject(1703450, "AutoFeed"),
    CurseForgeProject(1728015, "SmartRebuff"),
    CurseForgeProject(334372, "Questie", prefer="+v1.0"),
]

# Repo-owned helpers. CurseForge zips must not replace these.
REPO_OWNED = ("ConsolePortCouch", "CouchDictateRoute", "PlaterQuestPin")

# Installed with ConsolePort, but the couch leaves this one to the player.
DO_NOT_AUTO_ENABLE = ("ConsolePort_Keyboard",)


def update_projects() -> list[CurseForgeProject]:
    return [*CORE, *VOICE_PACKS, *QOL]
