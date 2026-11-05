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

### Campsite macro (Forever camping)

Account macro **Campsite** (created on login / `/cpcouch pincamp`):

```
#showtooltip
/click CPCCouchCamp
```

`ConsolePortCouch` picks, in order:

1. Best **campfire kit** in bags (Expert → Journeyman → Basic). If none, opens **Cooking** and crafts the best available kit (needs Flint and Tinder + Simple Wood / Star Wood / Thick Logs; ~10s cast — press Campsite again after)
2. Best **profession camp object** in bags (e.g. Fishing Hut → Rack → Fish Bowl; same for other professions)
3. `/sit` so camping buffs can tick (~1 min)

Errors / warnings (chat + UIErrorsFrame): dead, in combat, item on cooldown (features share a 1h CD), missing Cooking/wood/Flint and Tinder, or missing profession object. Visiting someone else’s camp with empty bags still sits, with a warning.

In-game: `/cpcouch camp` runs it; `/cpcouch campstatus` lists what is in bags. Drag **Campsite** onto a gamepad bar slot — not bound over RB. Offline seed: `./scripts/pin-campsite-macro.sh` (quit Forever first).

### FishingCouch macro (Forever fishing)

Account macro **FishingCouch** (created on login / `/cpcouch pinfish`):

```
#showtooltip Fishing
/click CPCCouchFish
```

Each press (out of combat):

1. Equips the best **fishing pole** in bags if better than what’s equipped
2. Applies the best **lure** if present and the pole has none
3. Eats Forever **+Fishing food** if present and not already Well Fed
4. Places **Fishing Hut / Rack / Bowl** (+ campfire kit) when those items are in bags
5. Always `/cast Fishing` — missing lure/food/camp objects are skipped quietly

Hard errors only for dead, combat, or no pole / no Fishing skill. `/cpcouch fish` runs it; `/cpcouch fishstatus` lists bags. Offline seed: `./scripts/pin-fishing-macro.sh`.

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
