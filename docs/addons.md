# Addons (Forever)

Flavor: **WoW Forever** client under `_forever_`, interface **`16001`** (game version `1.60.1`). Prefer CurseForge files that list `1.60.1` / Forever. Do not TOC-bump retail- or Classic-only builds.

**None of the new QoL addons are claimed working in-game until tested in a live Forever session.**

## CurseForge app (updates)

Official Overwolf CurseForge is installed as a **user Flatpak** (`com.overwolf.curseforge`) with filesystem access to `$WOW_PREFIX` (default `~/Games/battlenet`).

```bash
./scripts/install-curseforge.sh   # install/update Flatpak + overrides + launcher
curseforge-wow                    # ~/.local/bin wrapper → flatpak run …
```

First-run must be in **Desktop Mode** (Gaming Mode cannot finish the GUI setup):

1. `steamos-session-select desktop`
2. `curseforge-wow`
3. Add/scan the Forever client folder (contains `Wow.exe`) — path is written to `config/curseforge-forever-path.txt`. Do **not** select `Interface/AddOns`.
4. Install/update only Forever / `1.60.x` files.
5. `steamos-session-select gamescope` when done.

Repo install scripts remain the reproducible baseline; CurseForge is for ongoing updates after that.

## Stack overview

### Preserve (already installed)

| Addon | Version / evidence | Role |
|-------|-------------------|------|
| ConsolePort (+ modules) | 3.3.13 (`Interface` includes `16001`) | Controller / couch UI |
| Immersion | 1.4.61 | Quest/gossip UI (**TTS off**) |
| ForeverVO + `ForeverVO_Data_*` | v0.1.10 packs | Spoken quests/gossip |
| CouchDictateRoute | repo addon | Sticky say/party/raid for dictation |

### Install + enable (2026-11-03)

| Addon | CurseForge project | Forever file | Deps | Role |
|-------|-------------------|--------------|------|------|
| Syndicator | 988370 | `Syndicator-289.zip` (`## Version: 289`, Interface includes `16001`) | — | Inventory index backend |
| Baganator | 914482 | `Baganator-839.zip` (`## Version: 839`, Interface includes `16001`) | **Syndicator** | Bag/bank UI |
| Leatrix Plus | 94855 | `Leatrix_Plus-1.60.25-forever.zip` (`## Interface: 16001`) | — | QoL toggles |
| Plater | 100547 | `Plater-v662.zip` (`## Version: Plater-v662-Forever`, `## Interface: 16001`) | — | Tank nameplates |

**Nameplate choice:** Plater (not Platynator). Plater Forever file exists and better matches bear-tank needs (threat colors, enemy casts, scripting). Do not install both.

### Staged only (zip on disk, **not** in `Interface/AddOns`, **not** enabled)

Path: `config/addons-staging/staged/` (on the couch box under the project `config/`).

| Addon | Project | Staged file | Notes |
|-------|---------|-------------|-------|
| Questie | 334372 | `Questie-v12.3.1+v1.0.9.zip` | Forever file; open Forever quest-coverage issues upstream — activate later |
| BigWigs | 2382 | `BigWigs-v427.8.zip` | Preferred boss mod for couch (lighter). DBM also has Forever (`12.1.19`) but needs Classic modules pack — do not enable both |
| GTFO | 20697 | `GTFO-6.12.2.zip` | Bad-ground audio |
| Talents Forever | 1700435 | `TalentsForeverBook-0.38.14.zip` | Beta Forever talent planner (`/tf`) |
| Auctionator | 6124 | `Auctionator-341.zip` | AH helper |

## Built-in first (do not install)

Forever already ships tools that replace common Classic addons:

- **Edit Mode** — move/resize frames (skip Bartender/Dominos)
- **Cooldown Manager** — Options → Gameplay Enhancement
- **Built-in damage meter** — skip Details!/Skada unless you prefer them later
- **Combined bags** — optional; Baganator is an enhancement, not a requirement
- **Controller / click-cast** — ConsolePort owns couch input (skip Clique)

Do **not** install Storyline (overlaps Immersion), AdiBags/Bagnon/BetterBags (overlaps Baganator), or a second nameplate addon beside Plater.

## Install commands

```bash
./scripts/install-forever-addons.sh          # ConsolePort / Immersion / ForeverVO
./scripts/install-couch-dictate-route.sh     # CouchDictateRoute
./scripts/install-forever-qol-addons.sh      # Baganator stack + Plater + Leatrix; stages the rest
./scripts/enable-forever-addons.sh           # enables install set only (not staged)
./scripts/pin-voiceover-prefs.sh             # after WTF/Account exists
```

Zips cache under `config/addons-staging/` (gitignored). Backup before QoL install lived at `~/Backups/wow-addons-YYYYMMDD-HHMMSS/` on the couch host.

## Voiceover policy

Use **ForeverVO** for spoken lines. Keep **Immersion TTS off**. Do not install Storyline.

## Bear tank / Plater recommendations (config only — untested)

Priorities once in-world:

1. Threat coloring (you tank vs not)
2. Enemy cast bars readable at TV distance
3. Important debuffs on nameplates
4. Personal defensive CD visibility (pair with Forever Cooldown Manager / ConsolePort bars)
5. Party health via Blizzard/ConsolePort frames — avoid a second raid-frame suite for now

Exact Plater profile import is **untested** until Forever is playable.

## Leatrix / Baganator notes (recommendations — untested)

- Leatrix: enable only QoL you need (auto-sell junk, gossip shortcuts); avoid anything that fights ConsolePort cursor focus.
- Baganator: categories or single view; Syndicator powers tooltip “have on alts” counts.

## Launch-day tests (leave unchecked until live client)

- [ ] Character select → AddOns: ConsolePort*, Immersion, ForeverVO*, CouchDictateRoute, Syndicator, Baganator, Leatrix_Plus, Plater enabled
- [ ] Staged addons (Questie, BigWigs, GTFO, Talents Forever, Auctionator) **absent/disabled**
- [ ] Open bags → Baganator UI; tooltip counts via Syndicator
- [ ] `/leatrix` options open
- [ ] Plater: threat color on aggro; enemy casts readable on couch
- [ ] Immersion + ForeverVO only for quest VO; Immersion TTS off
- [ ] ConsolePort bars unchanged; no duplicate bag/quest dialogue UI
- [ ] Built-in meter, Cooldown Manager, Edit Mode still usable

## Compatibility evidence (research date 2026-11-03)

- CurseForge files API: Forever candidates selected when `gameVersions` contains `1.60.x`
- Installed TOC checks on box after unzip: Syndicator/Baganator include `16001`; Leatrix_Plus and Plater Forever builds are `16001`-only
- Community matrix (forevermastery Forever compatibility, Oct 31 2026) aligned with these Forever files; Questie called out for remaining Forever quest bugs — hence staged

## In-game commands (after first login)

`/consoleport`, `/immersion`, `/fvo`, `/fvo status`, `/cdr status`, `/leatrix`, Plater options (slash per Plater TOC), Baganator bag bind.
