# ConsolePort recommended bindings (couch)

## What was wrong

Choosing ConsolePort’s **“Start from a blank slate”** clears all gamepad bindings (including Blizzard defaults). Face buttons may still show Forever gamepad-bar clicks while **LB/RB/LT/RT stay empty** — that matches an unfinished manual setup.

## Recommended preset

Use ConsolePort’s built-in **Xbox** device preset:

- Steam Controller / Steam Input emulates Xbox 360 — CP’s own Xbox device blurb recommends this for Steam Input.
- Xbox Wireless controller uses the same layout.

| Button | Default role (Xbox preset) |
|--------|----------------------------|
| A (PAD1) | Jump (+ Shift/Ctrl utility layers) |
| B / X / Y | Action buttons (place ST/AoE/taunt spells on the gamepad bar) |
| LB | Interact / loot target |
| LT | Target nearest enemy |
| RB / RT | Primary action buttons + modifier layers |
| D-pad | Extra action bar slots |
| Back / Start | Bags / game menu (and map on Ctrl) |

Class abilities are **not** pre-slotted — after the preset loads, put spells on the ConsolePort gamepad action bar (drag in `/consoleport` or use the action placer). Conceptual bear layout: [`bear-tank-bindings.md`](bear-tank-bindings.md).

## Apply (automatic)

```bash
./scripts/install-consoleport-couch.sh
```

Then `/reload`. Addon `ConsolePortCouch` applies the Xbox preset when shoulders/triggers are empty (or once). Force: `/cpcouch apply`.

## Apply (manual in-game)

1. `/consoleport`
2. Open **Defaults** (or Bindings → presets)
3. Choose **Apply recommended bindings** — **not** “blank slate”
4. Confirm device is **Xbox** (Steam Input / Xbox pad)
5. `/reload` if bars look stale

## Do not

- Do not use blank slate unless you intend a full custom map.
- Do not force Steam Proton on the Battle.net shortcut (GE-Proton via launch script).
- Dictation stays outside ConsolePort: Steam Controller **left grip** → Insert; Xbox **R3** → Insert ([`forever-xbox-r3-insert.md`](../config/steam-input/forever-xbox-r3-insert.md)).
