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

### Couch macros (plain `/use` / `/cast` only)

Forever cannot use items from `/run`. Every couch macro is a normal account macro — same style as InviteNearest.

**Campsite** (`/cpcouch camp`):

```
#showtooltip
/use Expert Campfire Kit
/use Journeyman Campfire Kit
/use Basic Campfire Kit
```

**FishingCouch** (`/cpcouch fish`):

```
#showtooltip
/cast Fishing
```

**EatBest / DrinkBest** — addon rewrites these out of combat to the strongest food/drink in bags:

```
#showtooltip
/use <best food or drink name>
```

`/cpcouch eat` or `/cpcouch drink` rescans and prints the current target. Offline seeds: `./scripts/pin-campsite-macro.sh`, `./scripts/pin-fishing-macro.sh`, `./scripts/pin-eat-drink-macros.sh` (quit Forever first).

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
