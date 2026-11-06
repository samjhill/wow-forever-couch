# Blizzard controller UI (couch)

In-game bars, targeting, and menu navigation use **Forever’s built-in controller UI**. ConsolePort is not installed.

Put class abilities on the Blizzard gamepad action bar. Conceptual bear layout: [`bear-tank-bindings.md`](bear-tank-bindings.md).

`./scripts/pin-forever-graphics.sh` turns off gamepad cursor auto-enable so Menu/Start opens the game menu instead of only flipping the crosshair.

## Couch macros

These are normal account macros. Drag them onto the gamepad bar. Quit Forever before the offline seeds write `WTF`.

**InviteNearest** (`./scripts/pin-invite-nearest-macro.sh`) — accept a party popup, target the nearest friend, invite. The script binds it to **RB** (`PADRSHOULDER`) in `bindings-cache.wtf`, and parks **Interact** on LT when that bind is empty.

**Campsite** (`./scripts/pin-campsite-macro.sh`):

```
#showtooltip
/use Expert Campfire Kit
/use Journeyman Campfire Kit
/use Basic Campfire Kit
```

**FishingCouch** (`./scripts/pin-fishing-macro.sh`):

```
#showtooltip
/cast Fishing
```

**Wand** (`./scripts/pin-wand-macro.sh`) — start wand auto-shot. `!Shoot` keeps it going if the button is pressed again:

```
#showtooltip
/cast !Shoot
```

**Food / drink** — Forever **AutoFeed** (not a couch macro):

| Macro | Does |
| --- | --- |
| `AutoFeed` | Eat best food in bags |
| `AutoDrink` | Drink best water in bags |

Create with `/af`, then drag onto a bar.

## Dictation

Dictation stays outside the gamepad bars: Steam Controller **left grip** → Insert; Xbox **R3** → Insert ([`forever-xbox-r3-insert.md`](../config/steam-input/forever-xbox-r3-insert.md)).
