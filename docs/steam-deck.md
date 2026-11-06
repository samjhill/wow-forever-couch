# Steam Deck (and SteamOS-like) quick start

Same couch stack as the living-room Bazzite box. On Deck the **`deck`** profile auto-applies (gentler FPS, dictation off by default).

## Easiest install (Konsole — recommended)

1. Steam Deck → **Power** → **Switch to Desktop**.
2. Open **Konsole**.
3. Paste:

```bash
curl -fsSL https://raw.githubusercontent.com/samjhill/wow-forever-couch/main/install.sh | bash
```

4. When Battle.net opens on the **WoW Forever** install page, **log in** (and approve the authenticator if asked). Leave the window open; the script waits until `_forever_` appears. Click **Install** only if the page still shows a button.
5. When the script finishes, **Return to Gaming Mode** and launch **Battle.net (WoW Forever)** (Steam Input is already on; do not force Steam Proton).

That’s the whole discoverability path: one URL, one paste, one Battle.net login. No second bootstrap, no hand-made shortcut.

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
| Clone repo, GE-Proton, silent Battle.net setup | Yes |
| Open Forever install page + wait for `_forever_` | Yes (login still manual) |
| Forever addons, couch helpers, timers | Yes (once client exists) |
| Non-Steam shortcut + Steam Input | Yes (`add-steam-shortcut.sh`) |
| Periodic `git pull` + safe addon re-apply | Yes (timer + launch hook) |
| CurseForge Forever addon updates | Yes (6h timer + before Battle.net launch) |
| Battle.net login (+ rare Install click) | Manual once |
| Personal `config/live-setup` bindings snapshot | Opt-in (`WOW_COUCH_RESTORE_LIVE=1`) |

Addon enable against `WTF/Account` runs on the next Battle.net launch after your first in-game login (no second `curl | bash`).

If the shortcut helper fails (no Steam userdata yet), sign into Steam once and re-run `./scripts/add-steam-shortcut.sh`, or follow the manual steps in [`scripts/add-steam-shortcut.md`](../scripts/add-steam-shortcut.md).

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

Steam Input notes: [`config/steam-input/`](../config/steam-input/). In-game control is Blizzard’s controller UI ([`controller-bindings.md`](controller-bindings.md)).
