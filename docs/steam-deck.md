# Steam Deck (and SteamOS-like) quick start

One-click path for **Steam Deck**, **Bazzite**, or similar Gaming Mode + Desktop Mode hosts. Same repo as the living-room couch box; Deck uses the `deck` profile (gentler FPS, dictation off by default).

## What is automatic vs manual

| Step | Automatic? |
|------|------------|
| Clone repo, GE-Proton, Battle.net prefix, Forever addons, couch helpers | Yes (`bootstrap-steamos.sh`) |
| Periodic `git pull` + safe addon re-apply | Yes (systemd user timer + launch hook) |
| Battle.net login + install Forever | Manual once |
| Steam non-Steam shortcut + Steam Input | Manual once (2 minutes) |
| Your personal `config/live-setup` bindings snapshot | Opt-in only (`WOW_COUCH_RESTORE_LIVE=1`) |

## One-click (Desktop Mode)

1. Switch to **Desktop Mode**.
2. Download [`config/desktop/wow-forever-couch-bootstrap.desktop`](../config/desktop/wow-forever-couch-bootstrap.desktop) (or clone the repo).
3. Make it executable → double-click → **Trust and Launch** (Konsole runs the bootstrap).
4. When Battle.net is installed, launch it, log in, install **Forever** (not Retail), start Forever once.
5. Run the desktop launcher **again** (or `./scripts/bootstrap-steamos.sh`) so addons enable against `WTF/Account`.
6. Steam → **Add a Non-Steam Game** → browse to:

   `~/Projects/wow-forever-couch/scripts/launch-battlenet-lutris.sh`

   Rename to **Battle.net (WoW Forever)**. Compatibility: do **not** force Steam Proton. Enable **Steam Input**.
7. Return to **Gaming Mode** and launch that shortcut.

### CLI equivalent

```bash
git clone https://github.com/samjhill/wow-forever-couch.git ~/Projects/wow-forever-couch
cd ~/Projects/wow-forever-couch
./scripts/bootstrap-steamos.sh
# … install Forever via Battle.net …
./scripts/bootstrap-steamos.sh
```

Force the Deck profile (usually auto-detected):

```bash
export WOW_COUCH_PROFILE=deck
./scripts/bootstrap-steamos.sh
```

## Auto-sync when this repo updates

After bootstrap:

1. **systemd user timer** (`wow-forever-couch-update.timer`) every ~6 hours runs `apply-repo-updates.sh` in **full** mode.
2. **Launch hook** in `launch-battlenet-proton.sh` runs **quick** mode (ff-only pull + repo addon sync) before Battle.net starts.

Manual:

```bash
WOW_COUCH_UPDATE_MODE=full ./scripts/apply-repo-updates.sh
```

Opt-in personal prefs (your tuned box only; quit Forever first):

```bash
WOW_COUCH_RESTORE_LIVE=1 WOW_COUCH_UPDATE_MODE=full ./scripts/apply-repo-updates.sh
```

## Profiles

| Profile | File | Notes |
|---------|------|--------|
| `deck` | `profiles/deck.env` | Auto on Steam Deck / Jupiter / Galileo; 40 FPS DXVK default; dictation off |
| `bazzite-nvidia` | `profiles/bazzite-nvidia.env` | Living-room NVIDIA; 60 FPS; dictation on |

```bash
export WOW_COUCH_PROFILE=bazzite-nvidia
```

## Dictation on Deck (optional)

```bash
WOW_COUCH_DICTATION=1 ./scripts/bootstrap-steamos.sh
# or later:
./scripts/setup-whisper.sh
./scripts/install-user-services.sh
```

Mic routing differs per dock/BT headset — see [`voice-dictation.md`](voice-dictation.md).

## Controller

Import Steam Input notes under [`config/steam-input/`](../config/steam-input/). ConsolePort couch helpers install with the addon sync; empty shoulders → `/cpcouch apply` after login ([`controller-bindings.md`](controller-bindings.md)).
