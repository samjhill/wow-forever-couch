# WoW Forever couch gaming (Bazzite / SteamOS-like)

Opinionated setup for playing **World of Warcraft: Forever** from the couch on **Bazzite** (or similar Steam Gaming Mode + Desktop Mode Linux boxes):

- Battle.net under **GE-Proton**
- Steam **Gaming Mode** non-Steam shortcut
- **ConsolePort** + **Immersion** + **Forever Voiceover** (spoken quests)
- Optional **voice → Whisper → auto-type into WoW chat** (mic + controller grip)

Tested on Bazzite with an NVIDIA GPU, Steam Controller, and a RØDE Wireless GO II into the PC **mic-in** jack. Paths are configurable; defaults assume `~/Games/battlenet` for the Proton prefix.

> Not affiliated with Blizzard. Forever addons and voice packs come from their upstream authors (ConsolePort/Immersion, Forever Voiceover on CurseForge/GitHub).

## Quick start

```bash
git clone https://github.com/samjhill/wow-forever-couch.git
cd wow-forever-couch
```

### 1. Proton + Battle.net (Desktop Mode)

```bash
./scripts/install-ge-proton.sh
./scripts/install-battlenet-desktop.sh   # downloads installer if needed, runs under GE-Proton
./scripts/launch-battlenet-proton.sh    # log in, install Forever (not Retail)
```

Override the prefix if you want:

```bash
export WOW_PREFIX="$HOME/Games/battlenet"   # default
```

### 2. Forever addons

With Forever installed at least once (so `_forever_/Interface/AddOns` exists):

```bash
./scripts/install-forever-addons.sh        # ConsolePort, Immersion, ForeverVO + voice packs
./scripts/install-couch-dictate-route.sh   # sticky chat for dictation
./scripts/install-forever-qol-addons.sh    # Baganator/…/Lore Forever/Fishing Log; stages Questie/BW/…
./scripts/enable-forever-addons.sh         # after first login / WTF/Account exists
./scripts/pin-voiceover-prefs.sh           # Immersion TTS off; ForeverVO plays voices
./scripts/pin-forever-graphics.sh          # D3D11 + 60 FPS cap (NVIDIA/Proton); also runs on Battle.net launch
# Optional: restore a known-good prefs snapshot from this repo
./scripts/restore-live-setup.sh            # applies config/live-setup/ (quit Forever first)
```

Refresh the snapshot from a tuned play box: `./scripts/snapshot-live-setup.sh` then commit `config/live-setup/`. On this Mac, launchd autosaves every 4h — see [`docs/live-setup-autosave.md`](docs/live-setup-autosave.md).

In-game: enable the install set at character select. Use **ForeverVO for speech**, Immersion for quest UI only (keep Immersion TTS off). Do not stack Storyline with Immersion. Staged zips stay disabled until you activate them.

Details: [`docs/addons.md`](docs/addons.md).

### 3. Steam Gaming Mode shortcut

See [`scripts/add-steam-shortcut.md`](scripts/add-steam-shortcut.md). Point a non-Steam game at:

`…/wow-forever-couch/scripts/launch-battlenet-lutris.sh`

Enable **Steam Input**. Do **not** force Steam’s Proton on the shortcut (the script already uses GE-Proton).

### 4. Controller

- ConsolePort handles in-game bars/UI. Empty LB/RB/LT/RT → `./scripts/install-consoleport-couch.sh` then `/reload` ([`docs/controller-bindings.md`](docs/controller-bindings.md)).
- Steam Input dictation: Steam Controller **left grip → F20**; Xbox **R3 → F20** — [`config/steam-input/`](config/steam-input/).
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

**Default behavior:** after Whisper, inject **drafts** into chat (`Esc` → `Enter` → type). Press the dictate bind again (SC left grip / Xbox R3) to send. SC right grip or Esc cancels. Channel sticky: solo/party-of-2 → Say; party-of-3+ → Party; raid → Raid (see [`docs/voice-dictation.md`](docs/voice-dictation.md)).

```bash
DICTATE_NO_SEND=1 ./scripts/dictate-push-to-talk.sh          # clipboard only
DICTATE_SEND_MODE=send ./scripts/dictate-push-to-talk.sh     # auto final Enter
DICTATE_CHANNEL=party ./scripts/dictate-push-to-talk.sh      # manual /p override
```

## Layout

| Path | Purpose |
|------|---------|
| `scripts/` | Install, launch, addons, dictation |
| `addons/CouchDictateRoute/` | Sticky chat channel for voice dictation |
| `docs/` | Install, addons, controller, dictation, troubleshooting |
| `config/steam-input/` | Steam Input bind notes (export your share codes here) |

Environment variables used by scripts (via `scripts/lib.sh`):

| Variable | Default |
|----------|---------|
| `WOW_PREFIX` | `$HOME/Games/battlenet` |
| `WOW_FOREVER` | `…/World of Warcraft/_forever_` under that prefix |
| `REPO_ROOT` | Auto-detected from script location |

## Requirements

- Bazzite / SteamOS-like host with Desktop Mode + Gaming Mode
- Steam, GE-Proton (script installs **GE-Proton11-12** by default)
- For dictation: `ffmpeg`, `espeak-ng` (sim tests), `python3` + `evdev`, `ydotool`/`ydotoold`, PipeWire (`pw-record`)

## Safety

- Never commit Sunshine/RustDesk passwords or Battle.net credentials.
- Draft mode is the default; use `DICTATE_NO_SEND=1` while tuning the mic, and only enable `DICTATE_SEND_MODE=send` after in-game channel checks.
- Addon zips are downloaded by the install script (not vendored in git).

## License

MIT — see [`LICENSE`](LICENSE). Third-party addons remain under their own licenses.
