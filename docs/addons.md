# Addons (Forever)

## Stack

| Addon | Role |
|-------|------|
| ConsolePort (+ modules) | Controller / couch UI |
| Immersion | Quest/gossip UI (**TTS off**) |
| Forever Voiceover (`ForeverVO`) | Spoken quests/gossip (Forever-native VoiceOver) |
| `ForeverVO_Data_*` packs | Classic + Forever voice audio |

Install:

```bash
./scripts/install-forever-addons.sh
```

Zips cache under `config/addons-staging/` (gitignored).

## Voiceover policy

Use **ForeverVO** for spoken lines. Keep **Immersion TTS off** so they do not talk over each other. Do not install Storyline alongside Immersion.

```bash
./scripts/pin-voiceover-prefs.sh   # after WTF/Account exists
```

ForeverVO is for the Forever client. Classic “VoiceOver” by mrthinger does not target Forever.

## In-game

1. Character select → AddOns → enable ConsolePort*, Immersion, ForeverVO, ForeverVO_Data_*.
2. `/consoleport`, `/immersion`, `/fvo`.
3. `/fvo status` should list packs.
4. Missing Forever-only lines: play with ForeverVO on, then `/fvo export` and contribute upstream.
