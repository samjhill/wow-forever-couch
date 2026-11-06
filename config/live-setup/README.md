# Live couch setup snapshot

Captured **2026-11-06T10:18Z** from account `50188345#4` / character `unknown`.

## Contents

- `account/AddOns.txt` — enabled couch addons
- `account/SavedVariables/` — Immersion, Spoken (voice only), QoL
- `account/bindings-cache.wtf` — gamepad/key bindings cache
- `character/` — per-character Spoken and QoL SavedVariables
- `wtf/Config.wtf` — graphics pins (DX11, 60 FPS, vsync, …)
- `wtf/GamePadConfig_*.json` — client gamepad configs

## Restore

On the play box (Forever **fully quit**):

```bash
./scripts/restore-live-setup.sh
# optional: map into a different account/character
RESTORE_ACCOUNT=OtherAccount RESTORE_CHARACTER=91/MyChar ./scripts/restore-live-setup.sh
```

Then launch Forever. Do **not** commit secrets; this tree excludes capture DBs and passwords.
