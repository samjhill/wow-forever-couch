# Steam Input: Xbox R3 → Insert (dictation)

Use this when the **Xbox** pad is the couch controller.

Steam’s keyboard picker does **not** list F20. Bind **Insert** instead — the daemon listens for `KEY_INSERT` (and still accepts legacy F20).

| Controller | Dictate + send | Notes |
|------------|----------------|-------|
| Steam Controller | Left grip → Insert / `BTN_GRIPL` | |
| Xbox | **R3** → Insert / `BTN_THUMBR` | **Hold** to talk, **release** to Whisper + send |

## Apply

1. Library → **Battle.net (WoW Forever)** → Controller → **Enable Steam Input**.
2. Xbox layout for this shortcut.
3. Edit Layout → **Right Stick Click** / **R3**.
4. Bind → Keyboard → **Insert** (under Navigation / Editing keys). Use **Regular Press** (key stays down while R3 is held).
5. Save.

Hold R3 through your phrase; release to stop capture and send.

## Why Insert

- Visible in Steam’s keyboard list (unlike F13–F24 / F20).
- Unused by ConsolePort couch play; WoW rarely needs Insert on a gamepad.
- Under Steam Input, native `BTN_THUMBR` often never reaches the host — the keyboard bind is the reliable path.
