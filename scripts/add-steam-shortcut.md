# Add Steam shortcut (Desktop Mode)

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
