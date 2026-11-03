# Steam Input: left grip → F20 (dictation)

Target shortcut: **Battle.net (WoW Forever)**  
Daemon: `wow-dictate-daemon.service` listens for **KEY_F20** and native **BTN_GRIPL**.

## Apply (Gaming Mode or Desktop Steam)

1. Library → **Battle.net (WoW Forever)** → Controller / Properties → **Enable Steam Input**.
2. Edit Layout → find **Left Grip** (Steam Controller) or **L4 / Back Left** (Deck/Neptune).
3. Bind → Keyboard → **F20** (or “F20” under Function keys). Prefer *Regular Press*.
4. Optionally leave a native grip binding empty so the host `BTN_GRIPL` path also works; with Steam Input claiming the pad, F20 is the reliable path.
5. Save layout. Export / share code → paste into `docs/controller-layout.md`.

Do **not** force Steam Proton on this shortcut (uses GE-Proton via the launch script).

## Desktop quick test

```bash
systemctl --user status wow-dictate-daemon.service
# Simulate Steam Input F20 / harness FIFO:
echo fire > …/wow-forever-couch/config/dictate.trigger
```
