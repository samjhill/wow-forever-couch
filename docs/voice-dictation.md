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
```

Covers solo / party-2 → say, party-3+ → party, raid → raid, overrides, and slash prefixes. **Does not** prove in-client sticky behavior.

## In-game acceptance (do not check off until verified in Forever)

| Condition | Expected | Result |
|-----------|----------|--------|
| Solo | Draft opens on **Say** | Untested |
| Party of 2 | Draft opens on **Say** | Untested |
| Party of 3+ | Draft opens on **Party** | Untested |
| Raid | Draft opens on **Raid** | Untested |
| `/cdr party` then grip | Sticky/header shows Party | Untested |
| `DICTATE_CHANNEL=say` override | Typed text prefixed `/say ` | Untested |
| Draft confirm | Grip drafts; **second left grip** sends | Untested |
| Draft cancel | Right grip / FIFO `cancel` discards | Untested |
| `DICTATE_SEND_MODE=send` | Full Esc→Enter→type→Enter | Untested |

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
