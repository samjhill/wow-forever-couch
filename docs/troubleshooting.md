# Troubleshooting

## Battle.net / Forever

- `Battle.net.exe not found` → run `./scripts/install-battlenet-desktop.sh` from **Desktop Mode**.
- Forever missing AddOns folder → launch Forever once from Battle.net first.
- Gaming Mode shortcut fails → confirm the non-Steam entry points at `scripts/launch-battlenet-lutris.sh`, Steam Input on, Steam Proton **not** forced.

## Addons

- Addons missing in-game → character select → AddOns list; run `./scripts/enable-forever-addons.sh` after `WTF/Account` exists.
- ForeverVO silent → ensure `ForeverVO_Data_*` packs are enabled; `/fvo status`.
- Double speech → turn off Immersion TTS (`./scripts/pin-voiceover-prefs.sh`).

## Dictation

- No capture → `./scripts/prefer-mic-source.sh` (uses Bluetooth mic if connected, else PC mic-in); confirm BT is paired/connected or jack is in **mic-in**, TX unmuted.
- `ydotoold socket missing` → `./scripts/install-user-services.sh`.
- Types but not into WoW → Forever must be focused; test under the same session you play (Gaming Mode vs Desktop).
- Garbage drafts → lower mic gain / TV volume; use `DICTATE_NO_SEND=1` while tuning; left grip again sends, right grip cancels.
- Second grip starts a new recording instead of sending → draft expired (`DICTATE_DRAFT_TTL`, default 60s) or status wasn’t `draft`; check `config/dictate-status.json`.
- Wrong chat channel → `/cdr status`; `/cdr say|party|raid` or `DICTATE_CHANNEL=...` override; ensure CouchDictateRoute is enabled.

## Controller

- ConsolePort not binding → enable ConsolePort* modules; `/consoleport`.
- Grip does nothing for dictate → bind left grip → F20 in Steam Input for the Forever shortcut, and ensure `wow-dictate-daemon.service` is active.
