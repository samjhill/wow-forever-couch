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
| ConsolePortCouch | repo `addons/` | Applies Xbox recommended bindings once (Steam Input / Xbox) |
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
| PlaterQuestPin | repo `addons/` | Forces **Track Quests Progress** + **Use Quest Color** on enemy/friendly NPCs; sets `showQuestTrackingTooltips` so kill N/M lines appear for Plater to scan (`/platerquestpin`) |
| SelfBuffs | 1718593 | `SelfBuffs-v1.0.1-forever.zip` | — | Movable self buff/debuff icon strip + countdown (`/sb`) |
| CouchBuffReminder | repo `addons/` | Banner when class self-buffs are **missing** or &lt;60s left (`/cbr`) — pairs with SelfBuffs |
| Lore Forever | 1715510 | `LoreForever.zip` (`## Version: 0.37.0`, `## Interface: 16001`) | ships `LoreForever_Voice_Default*` | Zone/NPC/quest lore panel + optional story narration (`/lore`) |
| The Fishing Log | 1702832 | `TheFishingLog-1.0.0.zip` (`## Version: 1.0.0`, `## Interface: 16001`) | optional Auctionator/TSM for catch value | Catch log, journal, spot records, matches (`/tfl`) |

**Nameplate choice:** Plater (not Platynator). Plater Forever file exists and better matches bear-tank needs (threat colors, enemy casts, scripting). Do not install both.

**DialogKey:** Not installed. Immersion already owns keyboard/gamepad quest + gossip confirms (`padaccept` = PAD1); DialogKey would only add StaticPopup Space-click and overlaps Immersion’s baked-in numbers.

**Lore Forever:** Complements ForeverVO — lore Q&A and zone primers, not a quest-dubber. Leave **Speak quest dialogue** off (addon default). Do **not** install Lore Forever Quest Dialogue packs or Spoken/Chatty Little NPC alongside ForeverVO. Optional extra narrator language packs are fine; male English packs ship in the main zip. Untested in live Forever until launch checklist.

**The Fishing Log:** Forever-only fishing tracker. No overlap with the couch stack (profession QoL). Optional Auctionator pricing stays available once Auctionator is activated from staging. Untested in live Forever until launch checklist.

**Forever Loot Sparkles:** Keeps loot sparkles on quest items (graphics presets often turn them off). Optional herb/ore sparkles + gathering icon nearby. Options → AddOns → Forever Loot Sparkles.

**NodeSight:** Live herb/ore (and chest) icons on minimap tracking dots — needs Find Herbs / Find Minerals on. Optional nearest-node arrow + sparkles. Controller-friendly. `/nodesight` or Options → AddOns.

**Gather Radar:** Live gathering icons plus remembered herb/ore pins on minimap and world map; optional GatherMate2_Data import. `/gr` for settings. Turn on Find Herbs (or minerals/treasure/fish) to feed it.

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

Do **not** install Storyline (overlaps Immersion), DialogKey forks (Immersion already covers quest/gossip keys), AdiBags/Bagnon/BetterBags (overlaps Baganator), or a second nameplate addon beside Plater.

## Install commands

```bash
./scripts/install-forever-addons.sh          # ConsolePort / Immersion / ForeverVO
./scripts/install-couch-dictate-route.sh     # CouchDictateRoute
./scripts/install-forever-qol-addons.sh      # Baganator + Plater + Leatrix + Lore Forever + Fishing Log + Loot Sparkles + NodeSight + Gather Radar; stages the rest
./scripts/enable-forever-addons.sh           # enables install set only (not staged)
./scripts/install-consoleport-couch.sh       # Xbox recommended bindings helper (empty LB/RB/LT/RT)
./scripts/pin-voiceover-prefs.sh             # after WTF/Account exists
./scripts/snapshot-live-setup.sh             # save tuned prefs → config/live-setup/
./scripts/restore-live-setup.sh              # apply config/live-setup/ (Forever quit)
```

Zips cache under `config/addons-staging/` (gitignored). Backup before QoL install lived at `~/Backups/wow-addons-YYYYMMDD-HHMMSS/` on the couch host.

## Voiceover policy

Use **ForeverVO** for spoken quest/gossip lines. Keep **Immersion TTS off**. Keep ForeverVO **Show the panel** off (`pin-voiceover-prefs.sh`) so Immersion alone draws the quest UI. Keep Lore Forever **Speak quest dialogue** off. Do not install Storyline or Lore Forever Quest Dialogue packs.

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

- [x] Character `Chain-Milk` / account `SAMUHILL` exists; AddOns.txt enables ConsolePort*, Immersion, ForeverVO*, CouchDictateRoute, Syndicator, Baganator, Leatrix_Plus, Plater, LoreForever (+ Voice_Default*), TheFishingLog, ForeverLootSparkles, NodeSight, GatherRadar (DialogKey removed)
- [x] Staged addons (Questie, BigWigs, GTFO, Talents Forever, Auctionator) **absent** from AddOns.txt / not in live enable set
- [ ] Open bags → Baganator UI; tooltip counts via Syndicator
- [ ] `/leatrix` options open
- [ ] Plater: threat color on aggro; enemy casts readable on couch
- [ ] `/lore` opens Lore Forever; Speak quest dialogue still off; ForeverVO still speaks quests
- [ ] `/tfl journal` opens The Fishing Log; casting/lure helpers usable while fishing
- [x] Immersion + ForeverVO only for quest VO; Immersion TTS off; ForeverVO showPanel off (pinned in `config/live-setup/`)
- [x] ConsolePortCouch + bindings cache captured in `config/live-setup/`
- [ ] Built-in meter, Cooldown Manager, Edit Mode still usable
- [x] DX11 + maxFPS 60 in snapshot Config.wtf (`pin-forever-graphics.sh`)

## Compatibility evidence (research date 2026-11-03)

- CurseForge files API: Forever candidates selected when `gameVersions` contains `1.60.x`
- Installed TOC checks on box after unzip: Syndicator/Baganator include `16001`; Leatrix_Plus and Plater Forever builds are `16001`-only; LoreForever `0.37.0` and TheFishingLog `1.0.0` are `16001`-only
- Community matrix (forevermastery Forever compatibility, Oct 31 2026) aligned with these Forever files; Questie called out for remaining Forever quest bugs — hence staged

## In-game commands (after first login)

`/consoleport`, `/immersion`, `/fvo`, `/fvo status`, `/cdr status`, `/leatrix`, `/lore` (alias `/lf`), `/tfl` (`journal` / `here` / `config`), Plater options (slash per Plater TOC), Baganator bag bind.
