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
| LB | Interact / loot target (Xbox preset) |
| LT | Target nearest enemy; if empty, Couch parks **Interact** here when RB is remapped |
| RB | **InviteNearest** account macro (accept party popup + target nearest friend + invite) — pinned by ConsolePortCouch |
| RT | Primary action buttons + modifier layers |
| D-pad | Extra action bar slots |
| Back / Start | Bags / **Escape game menu** (ConsolePortCouch pins Start + System → `TOGGLEGAMEMENU`; cursor auto-enable off so Menu doesn’t only flip crosshair ↔ mouse) |

Class abilities are **not** pre-slotted — after the preset loads, put spells on the ConsolePort gamepad action bar (drag in `/consoleport` or use the action placer). Conceptual bear layout: [`bear-tank-bindings.md`](bear-tank-bindings.md).

## Apply (automatic)

```bash
./scripts/install-consoleport-couch.sh
```

Then `/reload`. Addon `ConsolePortCouch` applies the Xbox preset when shoulders/triggers are empty (or once), then pins **RB → InviteNearest**. Force: `/cpcouch apply`. Re-pin invite only: `/cpcouch invite`. Offline file seed: `./scripts/pin-invite-nearest-macro.sh` (quit Forever first for cache writes).

### Campsite / FishingCouch (plain Forever macros)

Forever’s secure-snippet path is broken, so these stay **plain account macros** (same idea as InviteNearest) — no `/run`, no SecureActionButton `/click`.

**Campsite** (`/cpcouch camp`):

```
#showtooltip
/use Expert Campfire Kit
/use Journeyman Campfire Kit
/use Basic Campfire Kit
/sit
```

Uses the first kit present in bags, then sits. Craft kits in Cooking beforehand if you have none.

**FishingCouch** (`/cpcouch fish`):

```
#showtooltip Fishing
/cast Fishing
```

Equip a pole (and lure) yourself; the macro only casts Fishing.

Drag either macro onto a ConsolePort gamepad bar slot (not over RB). Offline seeds: `./scripts/pin-campsite-macro.sh`, `./scripts/pin-fishing-macro.sh` (quit Forever first).

### EatBest / DrinkBest

Scans bags for the strongest health food / mana drink (tooltip “Restores N …”), skips alcohol, then uses it:

```
#showtooltip
/run if ConsolePortCouch_Eat then ConsolePortCouch_Eat() end
```

```
#showtooltip
/run if ConsolePortCouch_Drink then ConsolePortCouch_Drink() end
```

Created on login or `/cpcouch eat` / `/cpcouch drink`. Offline: `./scripts/pin-eat-drink-macros.sh`.

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
