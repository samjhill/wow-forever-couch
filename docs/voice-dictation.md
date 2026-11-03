# Voice dictation → WoW chat

## Goal

Controller left grip → speak → local Whisper → draft (or send) into Forever chat, with **group-aware channel routing**:

| Group state | Default channel |
|-------------|-----------------|
| Solo, or party of 1–2 | `/say` |
| Party of 3+ | `/party` |
| Raid | `/raid` |

Party-of-two uses `/say` on purpose: couch co-op in the same room does not need party spam.

## Architecture

```
Steam grip / F20 / FIFO
        │
        ▼
wow-dictate-daemon ──► dictate-push-to-talk.sh
                              │
                     Whisper (unchanged)
                              │
                              ▼
                     inject-wow-chat.sh
                     Esc → Enter → [optional /channel] type
                     [Enter only if DICTATE_SEND_MODE=send]
                              │
                              ▼
              Forever chat edit box (sticky type)
                              │
         CouchDictateRoute addon (in-client)
         GROUP_ROSTER_UPDATE → sticky SAY|PARTY|RAID
```

Two cooperating pieces:

1. **`CouchDictateRoute` addon** — observes `GROUP_ROSTER_UPDATE` / login and sets each chat edit box `chatType` + `stickyType` via `SetAttribute` + `ChatEdit_UpdateHeader`. When Enter opens chat, Blizzard uses that sticky type. The addon **never** calls `SendChatMessage`.
2. **Host inject** — still only simulates keys from your grip-triggered pipeline. Default mode is **draft** (no final Enter); **left grip again** confirms send (no keyboard Enter needed). Right grip (or FIFO `cancel`) presses Esc to discard.

### API / ToS notes

| Approach | Used? | Notes |
|----------|-------|-------|
| `IsInGroup` / `IsInRaid` / `GetNumGroupMembers` | Yes (addon) | Standard roster APIs on Forever (Interface 11xxx–12xxxx family). |
| `editBox:SetAttribute("chatType"\|"stickyType")` | Yes (addon) | Same path `ChatFrame_OpenChat` uses; not a protected/secure action; does not send. |
| `SendChatMessage` from addon | **No** | Would bypass physical confirm. |
| Memory read / client patch | **No** | Prohibited; also unnecessary. |
| Slash prefix override from host | Yes (fallback) | `DICTATE_CHANNEL=say\|party\|raid` types `/say` `/p` `/raid` so routing works even if sticky fails. |

## Setup

```bash
./scripts/setup-whisper.sh
./scripts/install-user-services.sh         # ydotoold + dictate daemon
./scripts/prefer-mic-source.sh             # PC mic-in
./scripts/install-couch-dictate-route.sh   # addon → Interface/AddOns
./scripts/enable-forever-addons.sh         # includes CouchDictateRoute
./scripts/test-channel-routing.sh          # offline policy tests
./scripts/test-dictate-harness.sh          # offline dictate checks
```

In-game: `/reload`, then `/cdr status`. Manual sticky override: `/cdr say|party|raid` or `/cdr auto`.

Steam Input: left grip → **F20** — see [`config/steam-input/forever-left-grip-f20.md`](../config/steam-input/forever-left-grip-f20.md).

## Workflow (current default: draft)

1. Forever focused; `CouchDictateRoute` loaded.
2. **Left grip** (or `echo fire > config/dictate.trigger`).
3. Speak (~4s, `DICTATE_SECS`).
4. Inject opens chat and types the transcript (**does not send**).
5. Read the draft → **left grip again** to send (daemon presses Enter).
6. Discard instead: **right grip**, or `echo cancel > config/dictate.trigger`, or Esc.

Pending drafts expire after `DICTATE_DRAFT_TTL` seconds (default 60); the next left grip then starts a new dictation instead of confirming.

Auto-send (after you trust routing in-game):

```bash
DICTATE_SEND_MODE=send ./scripts/dictate-push-to-talk.sh
# or export in the user unit / dictate-env sidecar
```

Clipboard-only (no inject):

```bash
DICTATE_NO_SEND=1 ./scripts/dictate-push-to-talk.sh
```

Manual channel override (host slash prefix; ignores sticky for that inject):

```bash
DICTATE_CHANNEL=party DICTATE_SEND_MODE=draft ./scripts/dictate-push-to-talk.sh
```

| Env | Default | Meaning |
|-----|---------|---------|
| `DICTATE_SEND_MODE` | `draft` | `draft` = type only; `send` = final Enter immediately |
| `DICTATE_CHANNEL` | `auto` | `auto` = bare text + addon sticky; `say`/`party`/`raid` = slash prefix |
| `DICTATE_DRAFT_TTL` | `60` | Seconds a draft stays confirmable via second grip |
| `DICTATE_NO_SEND` | unset | Skip inject entirely |
| `DICTATE_WAV` | unset | Replay file instead of mic |

Whisper capture/transcription is unchanged.

## Offline tests

```bash
./scripts/test-channel-routing.sh
./scripts/test-dictate-mock-wow.sh   # headless WoW chat mock (recommended)
```

`test-dictate-mock-wow.sh` starts `mock-wow-chat.py`, points inject/confirm at it via `DICTATE_MOCK_FIFO`, and asserts:

- draft text appears in the mock edit box
- second confirm sends; cancel discards
- sticky SAY for solo / party-of-2; PARTY for 3+; RAID for raid
- `DICTATE_CHANNEL` slash overrides
- optional Whisper WAV → draft → confirm when the model is installed

No Forever client or display required. Production still uses ydotool when `DICTATE_MOCK_FIFO` is unset.

## Host E2E (2026-11-03, Bazzite)

Verified without Forever focus (key inject + status machine):

| Step | Result |
|------|--------|
| `ydotoold` + `wow-dictate-daemon` | Pass |
| Offline channel policy unit tests | Pass |
| Whisper (`DICTATE_WAV`) → `state=draft` | Pass |
| Draft inject (no final Enter) | Pass |
| FIFO `confirm` → `state=sent` (Enter) | Pass |
| FIFO `cancel` → `state=cancelled` (Esc) | Pass |
| `DICTATE_CHANNEL=say\|party\|raid` on inject process | Pass |

Put env vars on the **inject/dictate** command, not on `printf` in a pipeline:

```bash
DICTATE_CHANNEL=party DICTATE_SEND_MODE=draft ./scripts/inject-wow-chat.sh <<< 'hello'
```

## In-game acceptance (Forever client)

**Not verified yet.** Do not treat channel sticky or on-screen drafts as working until these pass in-world.

| Condition | Expected | Result |
|-----------|----------|--------|
| Solo | Draft opens on **Say** | Blocked — never entered world |
| Party of 2 | Draft opens on **Say** | Blocked |
| Party of 3+ | Draft opens on **Party** | Blocked |
| Raid | Draft opens on **Raid** | Blocked |
| `/cdr party` then grip | Sticky/header shows Party | Blocked |
| `DICTATE_CHANNEL=say` override | Typed text prefixed `/say ` | Host inject Pass; in-game Blocked |
| Draft confirm | Grip drafts; **second left grip** sends | Host Pass; on-screen Blocked |
| Draft cancel | Right grip / FIFO `cancel` discards | Host Pass; on-screen Blocked |

### Blockers observed 2026-11-03

1. No character folders under `WTF/Account` — client has not entered the world on this install.
2. Prior Forever login failed with `ERROR_GAME_UTILITY_SERVER_NO_SERVER (34200)` (realm utility unavailable).
3. Moonlight not paired to Sunshine; cannot stream the TV/gamescope view from this Mac session yet.

Once realms are up: Gaming Mode → Forever → `/reload` → `/cdr status` → left grip → read draft → left grip to send.

## Limitations

- Sticky routing requires the addon enabled; without it, `DICTATE_CHANNEL=auto` uses whatever chat was last sticky (often Say).
- ConsolePort may remapping Enter for UI focus — if draft never appears, try Desktop Mode once or open chat manually then retest.
- Host cannot read group size without the addon or a slash override (no memory scraping).
- Mis-hears still appear in the edit box in draft mode; confirm with a second grip only when the text looks right.
- Esc/Enter briefly steals input — avoid gripping mid-combat.
- No physical Enter key needed: confirm is left grip → draft → left grip again.

## Services

| Unit | Role |
|------|------|
| `ydotoold.service` | uinput typing into the focused game |
| `wow-dictate-daemon.service` | grip / F20 / FIFO → `dictate-push-to-talk.sh` |
