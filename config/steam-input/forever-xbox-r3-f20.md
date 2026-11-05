# Steam Input: Xbox R3 → F20 (dictation)

Use this when the **Xbox** (or Xbox-layout) pad is the couch controller instead of a Steam Controller.

Daemon: `wow-dictate-daemon.service` listens for **KEY_F20**, native **BTN_THUMBR** (R3), and Steam Controller grips.

| Controller | Dictate / confirm draft | Cancel draft |
|------------|-------------------------|--------------|
| Steam Controller | Left grip → F20 / `BTN_GRIPL` | Right grip |
| Xbox | **R3** (right stick click) → F20 / `BTN_THUMBR` | Esc, or `echo cancel > config/dictate.trigger` |

ConsolePort’s Xbox preset leaves `PADRSTICK` unbound — R3 is free for host dictation.

## Apply (Gaming Mode or Desktop Steam)

1. Library → **Battle.net (WoW Forever)** → Controller → **Enable Steam Input**.
2. Pick the **Xbox** layout for this shortcut (separate from the Steam Controller layout).
3. Edit Layout → **Right Stick Click** / **R3** / **RS**.
4. Bind → Keyboard → **F20**. Prefer *Regular Press*.
5. Save. Optional: export share code into [`docs/controller-layout.md`](../../docs/controller-layout.md).

Do **not** force Steam Proton on this shortcut (GE-Proton via the launch script).

## Desktop quick test

```bash
systemctl --user status wow-dictate-daemon.service
# Simulate bind:
echo fire > …/wow-forever-couch/config/dictate.trigger
# Or press R3 on a raw Xbox pad (daemon watches BTN_THUMBR when Steam Input is off)
```

Under Steam Input, prefer the F20 binding — Steam often claims the pad so native `BTN_THUMBR` never reaches the host.
