# Add Steam shortcut (Desktop Mode)

## Automatic (preferred)

Bootstrap / `install.sh` already runs:

```bash
./scripts/add-steam-shortcut.sh
```

That writes a non-Steam entry named **Battle.net (WoW Forever)** pointing at
`scripts/launch-battlenet-lutris.sh`, turns on **Steam Input**, and does **not**
force Steam Proton (the launch script already uses GE-Proton). Steam is restarted
so Gaming Mode sees the shortcut.

Requires Steam userdata (sign into Steam once if the helper says so), then re-run.

## Manual fallback

1. Steam → Games → Add a Non-Steam Game → Browse  
2. Select `wow-forever-couch/scripts/launch-battlenet-lutris.sh`  
   (after bootstrap this is usually `~/Projects/wow-forever-couch/scripts/launch-battlenet-lutris.sh`)  
3. Rename to **Battle.net (WoW Forever)**  
4. Properties → Compatibility: do **not** force Steam Proton  
5. Controller: enable Steam Input  
6. Optional: bind left grip → Insert — [`config/steam-input/forever-left-grip-insert.md`](../config/steam-input/forever-left-grip-insert.md)

The launch script quietly runs `apply-repo-updates.sh` (quick mode) before Battle.net so Deck/Bazzite stay on latest `main`. Set `WOW_COUCH_LAUNCH_SYNC=0` to disable.

If the shortcut does not appear in Gaming Mode, restart Steam or return to the library.

Full Deck flow: [`docs/steam-deck.md`](../docs/steam-deck.md).
