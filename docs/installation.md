# Battle.net and WoW Forever installation

## Defaults

| Item | Default path (override with env) |
|------|----------------------------------|
| Proton prefix | `$WOW_PREFIX` → `~/Games/battlenet` |
| Battle.net.exe | `$WOW_PREFIX/pfx/drive_c/Program Files (x86)/Battle.net/Battle.net.exe` |
| Forever client | `$WOW_FOREVER` → `…/World of Warcraft/_forever_` |
| AddOns | `$WOW_ADDONS` |
| GE-Proton | `$WOW_COMPAT_TOOL` → newest `~/.local/share/Steam/compatibilitytools.d/GE-Proton*` (or pinned path) |

## Steps (Desktop Mode)

Prefer the one-liner ([`docs/steam-deck.md`](steam-deck.md)):

```bash
curl -fsSL https://raw.githubusercontent.com/samjhill/wow-forever-couch/main/install.sh | bash
```

Manual pieces (same order bootstrap uses):

1. `./scripts/install-ge-proton.sh`
2. `./scripts/install-battlenet-desktop.sh` — silent `--lang=enUS --installpath=…`
3. `./scripts/install-forever-client.sh` — opens `--game=WoWF --install`, waits for `_forever_`
4. Log into Battle.net when asked; click Install only if needed
5. Addon / timer / pin stack runs once the client exists
6. `./scripts/add-steam-shortcut.sh` — Gaming Mode entry + Steam Input
7. Gaming Mode → launch **Battle.net (WoW Forever)**

## After first Forever login

`WTF/Account` is created on first real login. The Battle.net launch script then runs:

```bash
./scripts/enable-forever-addons.sh
./scripts/pin-voiceover-prefs.sh
```

You can also run them by hand, plus:

```bash
./scripts/pin-forever-graphics.sh  # D3D11 + FPS cap for NVIDIA/Proton stability
./scripts/install-curseforge.sh    # Flatpak CurseForge for updates (Desktop Mode first-run)
```

Play from **Gaming Mode** when possible. See [`troubleshooting.md`](troubleshooting.md#graphics--audio-nvidia--proton) for screen-tear / HDMI audio notes.

Then character select → AddOns → enable ConsolePort*, Immersion, ForeverVO, and every `ForeverVO_Data_*`.

Point CurseForge at `$WOW_FOREVER` (the folder with `Wow.exe`), not `Interface/AddOns`. See [`addons.md`](addons.md#curseforge-app-updates).
