# Steam Input: left grip → Insert (dictation)

Target shortcut: **Battle.net (WoW Forever)**  
Daemon: `wow-dictate-daemon.service` listens for **KEY_INSERT**, native **BTN_GRIPL**, and legacy **KEY_F20**.

Steam’s picker does not offer F20 — use **Insert**.

## Apply

1. Library → **Battle.net (WoW Forever)** → Controller → **Enable Steam Input**.
2. Edit Layout → **Left Grip** (Steam Controller) or **L4**.
3. Bind → Keyboard → **Insert**. Prefer *Regular Press*.
4. Save.

## Desktop quick test

```bash
systemctl --user status wow-dictate-daemon.service
echo fire > …/wow-forever-couch/config/dictate.trigger
```
