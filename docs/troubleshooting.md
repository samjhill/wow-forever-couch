# Troubleshooting

## Battle.net / Forever

- `Battle.net.exe not found` → run `./scripts/install-battlenet-desktop.sh` from **Desktop Mode**.
- Forever missing AddOns folder → launch Forever once from Battle.net first.
- Gaming Mode shortcut fails → confirm the non-Steam entry points at `scripts/launch-battlenet-lutris.sh`, Steam Input on, Steam Proton **not** forced.

## Graphics / audio (NVIDIA + Proton)

Symptoms: occasional horizontal lines / frame slices, hitching, crackly HDMI audio.

Observed on the couch host (2026-11-04): Forever on **D3D12/vkd3d** under **Plasma Wayland**, `graphicsQuality` 4, RTX 4060 Ti idle-ish while an **i5-6500 (4c/4t)** sat near load average 8+. That pairing produces compositor tears and audio underruns more than GPU faults.

Mitigations (repo defaults):

```bash
./scripts/pin-forever-graphics.sh   # GxApi D3D11, vsync on, maxFPS 60; quality 3 once
# launch-battlenet-proton.sh runs the pin automatically and sets:
#   DXVK_FRAME_RATE=60  __GL_VRR_ALLOWED=0  PULSE_LATENCY_MSEC=60
```

Then **fully quit** Battle.net/Forever and relaunch so `Config.wtf` reloads.

Also:

- Prefer **Gaming Mode** for play (`steamos-session-select gamescope`); Desktop Mode is fine for installs/CurseForge.
- TV: enable Game Mode; disable motion smoothing / “game motion” enhancers.
- Raise quality later in-game if the CPU stays under ~70%; re-pin quality with `FOREVER_GRAPHICS_FORCE=1 ./scripts/pin-forever-graphics.sh` only when you want the script to overwrite the tier again.
- Dual `Wow.exe` audio clients on HDMI are normal (launcher helper + game); crackle usually tracks CPU hitching, not a second sound device.

## Addons

- Addons missing in-game → character select → AddOns list; run `./scripts/enable-forever-addons.sh` after `WTF/Account` exists.
- ForeverVO silent → ensure `ForeverVO_Data_*` packs are enabled; `/fvo status`.
- Double speech → turn off Immersion TTS (`./scripts/pin-voiceover-prefs.sh`).
- Duplicate quest UI (modern Immersion + parchment/classic underneath) → ForeverVO’s talking-head panel is also on. Run `./scripts/pin-voiceover-prefs.sh` (sets `showPanel = false`) or `/forevervo` → Display → clear **Show the panel**. Keep Immersion for the dialogue UI; ForeverVO for audio only.

## Dictation

- No capture / only “you” → Bose was on **A2DP** (music, no mic). Dictation switches to **Headset (HFP)** for the record then restores A2DP. `prefer-mic-source.sh` must print `bluez_input…`, not `*.monitor`.
- Silent capture aborted → mic muted or wrong source (Whisper won’t hallucinate into chat).
- `ydotoold socket missing` → `./scripts/install-user-services.sh`.
- Types but not into WoW → Forever must be focused; test under the same session you play (Gaming Mode vs Desktop).
- Garbage drafts → speak after the start beep (`DICTATE_SECS` default 6); `DICTATE_NO_SEND=1` while tuning.
- Second grip starts a new recording instead of sending → draft expired (`DICTATE_DRAFT_TTL`, default 60s) or status wasn’t `draft`; check `config/dictate-status.json`.
- Wrong chat channel → `/cdr status`; `/cdr say|party|raid` or `DICTATE_CHANNEL=...` override; ensure CouchDictateRoute is enabled.

## Controller

- ConsolePort not binding → enable ConsolePort* modules; `/consoleport`.
- Empty shoulders/triggers (blank slate) → `./scripts/install-consoleport-couch.sh` then `/reload`, or `/consoleport` → Defaults → **Apply recommended bindings** (Xbox). Force: `/cpcouch apply`. See [`controller-bindings.md`](controller-bindings.md).
- Dictate bind does nothing → Steam Controller: left grip → Insert; Xbox: **R3 → Insert** ([`forever-xbox-r3-insert.md`](../config/steam-input/forever-xbox-r3-insert.md)). Ensure `wow-dictate-daemon.service` is active (`systemctl --user restart wow-dictate-daemon`).
