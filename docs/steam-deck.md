# Steam Deck (and SteamOS-like) quick start

Same couch stack as the living-room Bazzite box. On Deck the **`deck`** profile auto-applies (gentler FPS, dictation off by default).

## Easiest install (Konsole — recommended)

1. Steam Deck → **Power** → **Switch to Desktop**.
2. Open **Konsole**.
3. Paste:

```bash
curl -fsSL https://raw.githubusercontent.com/samjhill/wow-forever-couch/main/install.sh | bash
```

4. When it finishes, start **Battle.net** from the script prompt / `./scripts/launch-battlenet-proton.sh`, log in, install **Forever** (not Retail), launch Forever once.
5. Paste the same `curl … | bash` line **again** (or double-click **Install WoW Forever Couch** on the Desktop) so addons enable against your account folder.
6. Steam (Desktop) → **Games** → **Add a Non-Steam Game** → browse to:

   `~/Projects/wow-forever-couch/scripts/launch-battlenet-lutris.sh`

   Rename to **Battle.net (WoW Forever)**. Do **not** force Steam Proton. Enable **Steam Input**.
7. **Return to Gaming Mode** and launch that shortcut.

That’s the whole discoverability path: one URL, one paste. No need to find GitHub folders first.

## Alternative: Desktop icon

If you prefer Dolphin over Konsole:

1. On a phone/PC open  
   https://github.com/samjhill/wow-forever-couch/blob/main/config/desktop/wow-forever-couch-bootstrap.desktop  
   → Download (or raw → save).
2. Move the file to **Desktop**.
3. Right-click → **Properties** → **Permissions** → enable **Is executable**.
4. Double-click → **Trust and Launch**.

Or after any clone/install, regenerate the icon:

```bash
~/Projects/wow-forever-couch/scripts/install-desktop-launcher.sh
```

## What is automatic vs manual

| Step | Automatic? |
|------|------------|
| Clone repo, GE-Proton, Battle.net prefix, Forever addons, couch helpers | Yes |
| Periodic `git pull` + safe addon re-apply | Yes (timer + launch hook) |
| CurseForge Forever addon updates | Yes (6h timer + before Battle.net launch) |
| Battle.net login + install Forever | Manual once |
| Steam non-Steam shortcut + Steam Input | Manual once (~2 minutes) |
| Personal `config/live-setup` bindings snapshot | Opt-in (`WOW_COUCH_RESTORE_LIVE=1`) |

## Auto-sync when this repo updates

After install:

1. **systemd user timer** (~every 6h) → full apply, plus CurseForge addon refresh  
2. **Battle.net launch** → quiet quick pull + repo addon sync + CurseForge Forever files  

Manual:

```bash
WOW_COUCH_UPDATE_MODE=full ~/Projects/wow-forever-couch/scripts/apply-repo-updates.sh
```

Your tuned prefs only (quit Forever first):

```bash
WOW_COUCH_RESTORE_LIVE=1 WOW_COUCH_UPDATE_MODE=full ~/Projects/wow-forever-couch/scripts/apply-repo-updates.sh
```

## Profiles

| Profile | When | Notes |
|---------|------|--------|
| `deck` | Auto on Steam Deck | 40 FPS DXVK default; dictation off |
| `bazzite-nvidia` | Auto on Bazzite (or set explicitly) | 60 FPS; dictation on |

```bash
export WOW_COUCH_PROFILE=deck   # usually unnecessary on Deck
```

## Dictation (optional)

```bash
WOW_COUCH_DICTATION=1 curl -fsSL https://raw.githubusercontent.com/samjhill/wow-forever-couch/main/install.sh | bash
```

## Controller

Steam Input notes: [`config/steam-input/`](../config/steam-input/). ConsolePort helpers ship with addon sync; empty shoulders → `/cpcouch apply` ([`controller-bindings.md`](controller-bindings.md)).
