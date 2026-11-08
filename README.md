# WoW Forever couch gaming (Bazzite / SteamOS-like / Windows)

Opinionated setup for playing **World of Warcraft: Forever** from the couch:

- **Linux (Bazzite / Steam Deck):** Battle.net under **GE-Proton**, Gaming Mode shortcut, optional voice dictation
- **Windows:** native Battle.net Forever path, same addon/pin stack, git auto-sync via Task Scheduler
- **Blizzard controller UI** + **Immersion** + **Spoken** (spoken quests)

Tested on Bazzite (NVIDIA) and designed for Steam Deck via the same Linux installer. Windows uses PowerShell + shared Python helpers. Defaults assume `~/Games/battlenet` for the Proton prefix on Linux, and `%ProgramFiles(x86)%\World of Warcraft\_forever_` on Windows.

> Not affiliated with Blizzard. Forever addons and voice packs come from their upstream authors (Immersion, Spoken on CurseForge/GitHub).

## Steam Deck / Bazzite — easiest install

**Desktop Mode → Konsole.** On a Steam Deck, run `passwd` first (SteamOS ships with no password, so `sudo` fails until you set one). Then paste:

```bash
curl -fsSL https://raw.githubusercontent.com/samjhill/wow-forever-couch/main/install.sh | bash
```

That installs GE-Proton, Battle.net, queues **Forever**, writes the Gaming Mode shortcut (Steam Input on), and applies the couch stack. **Log into Battle.net** when the window opens; leave it until Forever finishes. Then Gaming Mode → **Battle.net (WoW Forever)**. Full walkthrough: [`docs/steam-deck.md`](docs/steam-deck.md).

Prefer a Desktop icon instead? Download [`Install WoW Forever Couch`](config/desktop/wow-forever-couch-bootstrap.desktop) → mark executable → Trust and Launch.

## Windows — easiest install

**PowerShell → paste** (Forever should already be installed via Battle.net):

```powershell
irm https://raw.githubusercontent.com/samjhill/wow-forever-couch/main/install.ps1 | iex
```

Installs addons/pins, a 6h repo-sync task, a daily CurseForge addon task, and a desktop shortcut. Needs Git + Python 3 (bootstrap can winget them). Full notes: [`docs/windows.md`](docs/windows.md).

**Dictation: Linux only for now** (Windows Phase 2).

## Quick start (manual clone)

```bash
git clone https://github.com/samjhill/wow-forever-couch.git
cd wow-forever-couch
./scripts/bootstrap-steamos.sh
# log into Battle.net when prompted; script waits for Forever + adds the Steam shortcut
WOW_COUCH_UPDATE_MODE=full ./scripts/apply-repo-updates.sh   # manual sync anytime
```

### 1. Proton + Battle.net (Desktop Mode)

```bash
./scripts/install-ge-proton.sh
./scripts/install-battlenet-desktop.sh   # silent install under GE-Proton
./scripts/install-forever-client.sh      # --game=WoWF --install; wait for _forever_
# or open the launcher anytime:
./scripts/launch-battlenet-proton.sh
```

Override the prefix if you want:

```bash
export WOW_PREFIX="$HOME/Games/battlenet"   # default
```

### 2. Forever addons

With Forever installed at least once (so `_forever_/Interface/AddOns` exists):

```bash
./scripts/install-forever-addons.sh        # Immersion, Spoken + English voice packs
./scripts/install-couch-dictate-route.sh   # sticky chat for dictation
./scripts/install-forever-qol-addons.sh    # Leatrix/…/Questie; stages BigWigs/GTFO/…
./scripts/install-curseforge-update-timer.sh  # refresh CurseForge Forever files daily
./scripts/enable-forever-addons.sh         # after first login / WTF/Account exists (also on Battle.net launch)
./scripts/pin-voiceover-prefs.sh           # Immersion TTS off; Spoken voice only
./scripts/pin-forever-graphics.sh          # D3D11 + 60 FPS cap (NVIDIA/Proton); also runs on Battle.net launch
# Optional: restore a known-good prefs snapshot from this repo
./scripts/restore-live-setup.sh            # applies config/live-setup/ (quit Forever first)
```

Refresh the snapshot from a tuned play box: `./scripts/snapshot-live-setup.sh` then commit `config/live-setup/`. On this Mac, launchd autosaves every 4h — see [`docs/live-setup-autosave.md`](docs/live-setup-autosave.md).

In-game: enable the install set at character select. Use **Spoken for speech**, Immersion for quest UI only (keep Immersion TTS off, Spoken narrator **Voice Only**). Do not stack Storyline with Immersion. Staged zips stay disabled until you activate them.

Details: [`docs/addons.md`](docs/addons.md).

### 3. Steam Gaming Mode shortcut

Bootstrap runs [`scripts/add-steam-shortcut.sh`](scripts/add-steam-shortcut.sh) automatically. Manual fallback: [`scripts/add-steam-shortcut.md`](scripts/add-steam-shortcut.md).

### 4. Controller

- Blizzard’s controller UI handles in-game bars and menus ([`docs/controller-bindings.md`](docs/controller-bindings.md)).
- Steam Input dictation: Steam Controller **left grip → Insert**; Xbox **R3 → Insert** — [`config/steam-input/`](config/steam-input/).
- Draft layouts: [`docs/controller-layout.md`](docs/controller-layout.md), bear/PvP notes under `docs/`.

### 5. Voice → chat (optional)

```bash
./scripts/setup-whisper.sh                 # whisper.cpp + base.en model
./scripts/install-user-services.sh         # ydotoold + dictate daemon
./scripts/prefer-mic-source.sh             # Bluetooth mic if connected, else built-in analog mic-in
./scripts/install-couch-dictate-route.sh   # sticky say/party/raid by group size
./scripts/test-channel-routing.sh          # offline channel policy tests
./scripts/test-dictate-mock-wow.sh         # headless mock WoW chat (draft/confirm/channels)
./scripts/test-dictate-harness.sh          # offline dictate checks
```

**Default behavior:** one dictate bind (SC left grip / Xbox R3) → record → Whisper → type into chat and **send**. Channel sticky: solo/party-of-2 → Say; party-of-3+ → Party; raid → Raid (see [`docs/voice-dictation.md`](docs/voice-dictation.md)).

```bash
DICTATE_NO_SEND=1 ./scripts/dictate-push-to-talk.sh            # clipboard only
DICTATE_SEND_MODE=draft ./scripts/dictate-push-to-talk.sh      # type only; bind again to send
DICTATE_CHANNEL=party ./scripts/dictate-push-to-talk.sh        # manual /p override
```

## Layout

| Path | Purpose |
|------|---------|
| `scripts/` | Install, launch, addons, dictation (Linux); `*.ps1` for Windows |
| `scripts/python/` | Shared CurseForge fetch / unzip / enable / pin helpers |
| `addons/CouchDictateRoute/` | Sticky chat channel for voice dictation |
| `docs/` | Install, addons, controller, dictation, Windows, troubleshooting |
| `config/steam-input/` | Steam Input bind notes (export your share codes here) |

Environment variables used by scripts (via `scripts/lib.sh` / `scripts/lib.ps1`):

| Variable | Linux default | Windows default |
|----------|---------------|-----------------|
| `WOW_PREFIX` | `$HOME/Games/battlenet` | n/a (native client) |
| `WOW_FOREVER` | `…/World of Warcraft/_forever_` under that prefix | `%ProgramFiles(x86)%\World of Warcraft\_forever_` |
| `REPO_ROOT` | Auto-detected from script location | same |

## Requirements

- **Linux:** Bazzite / SteamOS-like host with Desktop Mode + Gaming Mode; Steam; GE-Proton (script installs the latest GE-Proton release; launch prefers `WOW_COMPAT_TOOL` or newest installed)
- **Windows:** Forever via Battle.net; Git; Python 3
- **Dictation (Linux only):** `ffmpeg`, `espeak-ng` (sim tests), `python3` + `evdev`, `ydotool`/`ydotoold`, PipeWire (`pw-record`)

## Safety

- Never commit Sunshine/RustDesk passwords or Battle.net credentials.
- Auto-send is the default; use `DICTATE_NO_SEND=1` while tuning the mic, or `DICTATE_SEND_MODE=draft` to preview before sending.
- Addon zips are downloaded by the install script (not vendored in git).

## License

MIT — see [`LICENSE`](LICENSE). Third-party addons remain under their own licenses.
