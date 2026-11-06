# Addons (Forever)

Flavor: **WoW Forever** client under `_forever_`, interface **`16001`** (game version `1.60.1`). Prefer CurseForge files that list `1.60.1` / Forever. Do not TOC-bump retail- or Classic-only builds.

**None of the new QoL addons are claimed working in-game until tested in a live Forever session.**

## CurseForge updates

Forever files are refreshed from the CurseForge file list (game version `1.60.x` only):

- **Before Battle.net starts**, when you launch through `launch-battlenet-proton.sh` (skip with `WOW_COUCH_CURSEFORGE_UPDATE=0`)
- **Every 6 hours** via the user timer `wow-curseforge-addons.timer`
- **Full repo sync** (`WOW_COUCH_UPDATE_MODE=full`) also runs the same update

```bash
./scripts/install-curseforge-update-timer.sh
./scripts/update-curseforge-addons.sh
```

The job skips while Forever is running, leaves repo addons (`CouchDictateRoute`, `PlaterQuestPin`) alone, and does not install the staged set. A changed zip is extracted; an unchanged one is left in place. SavedVariables are not touched.

The Overwolf CurseForge Flatpak is optional browsing. It has no headless update command, and Gaming Mode will not keep that window running.

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

## Stack overview

### Preserve (already installed)

| Addon | Version / evidence | Role |
|-------|-------------------|------|
| Immersion | 1.4.61 | Quest/gossip UI (**TTS off**) |
| Spoken + `Spoken_*` + English audio packs | CurseForge Spoken 3.8.x | Quest, gossip, places, books, and boss narration (**Voice Only**) |
| CouchDictateRoute | repo addon | Sticky say/party/raid for dictation |

### Install + enable (2026-11-03)

| Addon | CurseForge project | Forever file | Deps | Role |
|-------|-------------------|--------------|------|------|
| Leatrix Plus | 94855 | `Leatrix_Plus-1.60.25-forever.zip` (`## Interface: 16001`) | — | QoL toggles |
| Plater | 100547 | `Plater-v662.zip` (`## Version: Plater-v662-Forever`, `## Interface: 16001`) | — | Tank nameplates |
| PlaterQuestPin | repo `addons/` | Forces **Track Quests Progress** + **Use Quest Color** on enemy/friendly NPCs; sets `showQuestTrackingTooltips` so kill N/M lines appear for Plater to scan (`/platerquestpin`) |
| AutoFeed | 1703450 | `AutoFeed-v1.4.0.zip` | — | Self-updating `AutoFeed` (eat) + `AutoDrink` macros (`/af`) |
| SmartRebuff | 1728015 | `SmartRebuff_1.60.zip` | — | Forever class/group buff monitor + renewal reminders (replaces SelfBuffs / CouchBuffReminder) |
| Questie | 334372 | `Questie-v12.3.1+v1.0.9.zip` | **QuestieDB** (same zip) | Quest tracker, map pins, and arrow. Forever TOC is `Questie_Camelot.toc` (`16001`). Some Forever quests are still missing upstream |
| Lore Forever | 1715510 | `LoreForever.zip` (`## Version: 0.37.0`, `## Interface: 16001`) | ships `LoreForever_Voice_Default*` | Zone/NPC/quest lore panel + optional story narration (`/lore`) |
| The Fishing Log | 1702832 | `TheFishingLog-1.0.0.zip` (`## Version: 1.0.0`, `## Interface: 16001`) | optional Auctionator/TSM for catch value | Catch log, journal, spot records, matches (`/tfl`) |

**Nameplate choice:** Plater (not Platynator). Plater Forever file exists and better matches bear-tank needs (threat colors, enemy casts, scripting). Do not install both.

**DialogKey:** Not installed. Immersion already owns keyboard/gamepad quest + gossip confirms (`padaccept` = PAD1); DialogKey would only add StaticPopup Space-click and overlaps Immersion’s baked-in numbers.

**Lore Forever:** Lore Q&A and zone primers, not the quest dubber. Leave **Speak quest dialogue** off (addon default). Do **not** install Lore Forever Quest Dialogue packs or Chatty Little NPC alongside Spoken. Spoken already narrates places; turn off one of the two if zone stories play twice. Optional extra narrator language packs are fine; male English packs ship in the main zip. Untested in live Forever until launch checklist.

**The Fishing Log:** Forever-only fishing tracker. No overlap with the couch stack (profession QoL). Optional Auctionator pricing stays available once Auctionator is activated from staging. Untested in live Forever until launch checklist.

**Forever Loot Sparkles:** Keeps loot sparkles on quest items (graphics presets often turn them off). Optional herb/ore sparkles + gathering icon nearby. Options → AddOns → Forever Loot Sparkles.

**NodeSight:** Live herb/ore (and chest) icons on minimap tracking dots — needs Find Herbs / Find Minerals on. Optional nearest-node arrow + sparkles. Controller-friendly. `/nodesight` or Options → AddOns.

### Staged only (zip on disk, **not** in `Interface/AddOns`, **not** enabled)

Path: `config/addons-staging/staged/` (on the couch box under the project `config/`).

| Addon | Project | Staged file | Notes |
|-------|---------|-------------|-------|
| BigWigs | 2382 | `BigWigs-v427.8.zip` | Preferred boss mod for couch (lighter). DBM also has Forever (`12.1.19`) but needs Classic modules pack — do not enable both |
| GTFO | 20697 | `GTFO-6.12.2.zip` | Bad-ground audio |
| Talents Forever | 1700435 | `TalentsForeverBook-0.38.14.zip` | Beta Forever talent planner (`/tf`) |
| Auctionator | 6124 | `Auctionator-341.zip` | AH helper |

## Built-in first (do not install)

Forever already ships tools that replace common Classic addons:

- **Edit Mode** — move/resize frames (skip Bartender/Dominos)
- **Cooldown Manager** — Options → Gameplay Enhancement
- **Built-in damage meter** — skip Details!/Skada unless you prefer them later
- **Combined bags** — use Forever’s built-in bags
- **Controller / click-cast** — Blizzard’s controller UI owns couch input (skip ConsolePort and Clique)

Do **not** install Storyline (overlaps Immersion), DialogKey forks (Immersion already covers quest/gossip keys), Baganator/Syndicator, Gather Radar, AdiBags/Bagnon/BetterBags, or a second nameplate addon beside Plater.

## Install commands

```bash
./scripts/install-forever-addons.sh          # Immersion / Spoken + English audio
./scripts/install-couch-dictate-route.sh     # CouchDictateRoute
./scripts/install-forever-qol-addons.sh      # Plater + Leatrix + Lore Forever + Fishing Log + Loot Sparkles + NodeSight + Questie; stages the rest
./scripts/enable-forever-addons.sh           # enables install set only (not staged); disables ConsolePort and ForeverVO
./scripts/pin-voiceover-prefs.sh             # after WTF/Account exists
./scripts/snapshot-live-setup.sh             # save tuned prefs → config/live-setup/
./scripts/restore-live-setup.sh              # apply config/live-setup/ (Forever quit)
```

Zips cache under `config/addons-staging/` (gitignored). Backup before QoL install lived at `~/Backups/wow-addons-YYYYMMDD-HHMMSS/` on the couch host.

## Voiceover policy

Use **Spoken** for spoken quest, gossip, place, book, and boss lines. Keep **Immersion TTS off**. Keep Spoken’s narrator style on **Voice Only** (`pin-voiceover-prefs.sh`, `Frame.Style = "none"`) so Immersion alone draws the quest UI. Keep Lore Forever **Speak quest dialogue** off. Do not install Storyline, Forever Voiceover, or Lore Forever Quest Dialogue packs.

## Bear tank / Plater recommendations (config only — untested)

Priorities once in-world:

1. Threat coloring (you tank vs not)
2. Enemy cast bars readable at TV distance
3. Important debuffs on nameplates
4. Personal defensive CD visibility (pair with Forever Cooldown Manager / the Blizzard gamepad bar)
5. Party health via Blizzard frames — avoid a second raid-frame suite for now

Exact Plater profile import is **untested** until Forever is playable.

## Leatrix notes (recommendations — untested)

- Leatrix: enable only QoL you need (auto-sell junk, gossip shortcuts); avoid anything that fights the controller cursor.

## Launch-day tests (leave unchecked until live client)

- [x] Character `Chain-Milk` / account `SAMUHILL` exists; AddOns.txt enables Immersion, Spoken (+ modules and English audio), CouchDictateRoute, Leatrix_Plus, Plater, LoreForever (+ Voice_Default*), TheFishingLog, ForeverLootSparkles, NodeSight, QuestieDB, Questie (DialogKey, ConsolePort, ForeverVO, Baganator, Syndicator, and GatherRadar removed)
- [x] Staged addons (BigWigs, GTFO, Talents Forever, Auctionator) **absent** from AddOns.txt / not in live enable set
- [ ] Open bags → Forever’s built-in bag UI
- [ ] `/leatrix` options open
- [ ] Plater: threat color on aggro; enemy casts readable on couch
- [ ] `/lore` opens Lore Forever; Speak quest dialogue still off; Spoken still speaks quests
- [ ] `/tfl journal` opens The Fishing Log; casting/lure helpers usable while fishing
- [x] Immersion + Spoken for quest VO; Immersion TTS off; Spoken narrator Voice Only (pinned in `config/live-setup/`)
- [x] Blizzard controller UI; ConsolePort left disabled in `config/live-setup/`
- [ ] Built-in meter, Cooldown Manager, Edit Mode still usable
- [x] DX11 + maxFPS 60 in snapshot Config.wtf (`pin-forever-graphics.sh`)

## Compatibility evidence (research date 2026-11-03)

- CurseForge files API: Forever candidates selected when `gameVersions` contains `1.60.x`
- Installed TOC checks on box after unzip: Leatrix_Plus and Plater Forever builds are `16001`-only; LoreForever `0.37.0` and TheFishingLog `1.0.0` are `16001`-only
- Community matrix (forevermastery Forever compatibility, Oct 31 2026) aligned with these Forever files. Questie `v12.3.1+v1.0.9` lists `1.60.1` and is installed; some Forever-only quests can still be missing upstream

## In-game commands (after first login)

`/immersion`, `/sp options`, `/cdr status`, `/leatrix`, `/lore` (alias `/lf`), `/tfl` (`journal` / `here` / `config`), Plater options (slash per Plater TOC).
