# Voice dictation → WoW chat

## Goal

Controller left grip → speak → local Whisper → **auto open/type/send** into Forever chat (default Enter channel, usually `/say`).

## Setup

```bash
./scripts/setup-whisper.sh
./scripts/install-user-services.sh    # ydotoold + dictate daemon
./scripts/prefer-mic-source.sh        # built-in analog mic-in
./scripts/test-dictate-harness.sh     # offline checks
```

Steam Input (recommended): left grip → **F20** — see [`config/steam-input/forever-left-grip-f20.md`](../config/steam-input/forever-left-grip-f20.md). The daemon also listens for Steam Controller `BTN_GRIPL`.

This repo defaults to **PC mic-in** (3.5mm into the motherboard). USB audio from some wireless RX units is flaky; jack path is more reliable for STT.

## Workflow

1. Forever focused.
2. Press left grip (or write `fire` to `config/dictate.trigger`).
3. Speak (~4s default, `DICTATE_SECS`).
4. Transcript is injected: Esc → Enter → type → Enter.

Debug without sending:

```bash
DICTATE_NO_SEND=1 ./scripts/dictate-push-to-talk.sh
```

Simulated speech (no mic):

```bash
./scripts/test-dictate-simulated.sh
```

## Risks

- Mis-hears **will send** to the default chat channel.
- Esc/Enter briefly steals input — avoid gripping mid-combat.
- Lower TV volume / lav positioning to reduce echo into Whisper.
- Hot mic levels can clip; reduce TX gain if needed.

## Services

| Unit | Role |
|------|------|
| `ydotoold.service` | uinput typing into the focused game |
| `wow-dictate-daemon.service` | grip / F20 / FIFO → `dictate-push-to-talk.sh` |
