# Battle.net and WoW Forever installation

## Defaults

| Item | Default path (override with env) |
|------|----------------------------------|
| Proton prefix | `$WOW_PREFIX` → `~/Games/battlenet` |
| Battle.net.exe | `$WOW_PREFIX/pfx/drive_c/Program Files (x86)/Battle.net/Battle.net.exe` |
| Forever client | `$WOW_FOREVER` → `…/World of Warcraft/_forever_` |
| AddOns | `$WOW_ADDONS` |
| GE-Proton | `~/.local/share/Steam/compatibilitytools.d/GE-Proton11-12` |

## Steps (Desktop Mode)

1. `./scripts/install-ge-proton.sh`
2. `./scripts/install-battlenet-desktop.sh`
3. `./scripts/launch-battlenet-proton.sh` — log in, install **Forever** (not Retail).
4. Play once from Battle.net to create the `_forever_` tree.
5. `./scripts/install-forever-addons.sh`
6. Add Steam non-Steam shortcut — [`scripts/add-steam-shortcut.md`](../scripts/add-steam-shortcut.md).
7. Gaming Mode → launch the shortcut → enable Steam Input.

## After first Forever login

```bash
./scripts/enable-forever-addons.sh
./scripts/pin-voiceover-prefs.sh
./scripts/pin-forever-graphics.sh  # D3D11 + FPS cap for NVIDIA/Proton stability
./scripts/install-curseforge.sh    # Flatpak CurseForge for updates (Desktop Mode first-run)
```

Play from **Gaming Mode** when possible. See [`troubleshooting.md`](troubleshooting.md#graphics--audio-nvidia--proton) for screen-tear / HDMI audio notes.

Then character select → AddOns → enable ConsolePort*, Immersion, ForeverVO, and every `ForeverVO_Data_*`.

Point CurseForge at `$WOW_FOREVER` (the folder with `Wow.exe`), not `Interface/AddOns`. See [`addons.md`](addons.md#curseforge-app-updates).
