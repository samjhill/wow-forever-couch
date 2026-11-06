# Controller layout (Steam Controller primary)

## Hardware

| Controller | Status |
|------------|--------|
| Steam Controller (dongle) | Connected — **primary** |
| Xbox Wireless Controller (BT) | Paired — alternate |

Steam Input should manage both. Do not overwrite unrelated game profiles.

## Layers

1. **Steam Input** outer profile for the non-Steam Battle.net / Forever entry (menu chords, dictation hotkey, desktop fallback).
2. **Blizzard controller UI** for in-game action bars, targeting, and menus.
3. **Immersion** face-button / gamepad bindings for quest gossip (`padaccept` = PAD1).

## Steam Controller conceptual map (Forever + Blizzard controller UI)

| Input | Role |
|-------|------|
| Left pad / stick | Movement |
| Right pad | Camera (mouse-look style if needed) |
| A / B / X / Y | Gamepad action bar face buttons |
| LB / RB | Target / modifier |
| LT / RT | Action layers |
| Grip L / R (Steam Controller) | **Left grip → dictation** (Insert / `BTN_GRIPL`); right grip cancels draft |
| R3 (Xbox) | **Dictation** (Insert / `BTN_THUMBR`) — see [`forever-xbox-r3-insert.md`](../config/steam-input/forever-xbox-r3-insert.md) |
| Steam button | Steam overlay / chord |
| Start / Select | Game menu / map |

Ability placement: [`bear-tank-bindings.md`](bear-tank-bindings.md) and [`controller-bindings.md`](controller-bindings.md).

## Xbox alternate

Simpler bumper/trigger layout; no trackpad radials. Same class loadout on the Blizzard gamepad bar; Steam Input profile named `WoW Forever Xbox` once exported.

## Export

After tuning in Gaming Mode: Steam → Controller settings → Export profile → copy to `config/steam-input/` and note the share code here.

| Profile | Share code / file | Date |
|---------|-------------------|------|
| Steam Controller Forever | Pending | |
| Xbox Forever | Pending | |


## Dictation bind (2026-11-03)

See [`config/steam-input/forever-left-grip-insert.md`](../config/steam-input/forever-left-grip-insert.md).

| Profile | Share code / file | Date |
|---------|-------------------|------|
| Steam Controller Forever (grip→Insert) | Pending export after apply | 2026-11-03 |
| Xbox Forever (R3→Insert) | Pending export after apply | 2026-11-05 |
