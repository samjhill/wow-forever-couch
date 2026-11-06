# Windows (native Battle.net Forever)

Core couch stack for **Windows**: Forever path detection, addon install/enable, prefs pins, and git auto-sync via Task Scheduler. No Proton, Gaming Mode, or voice dictation in this cut.

> **Dictation: Linux only for now** (Phase 2 on Windows — AutoHotkey / mic capture + whisper.cpp).

## Easiest install

In **PowerShell** (user scope is enough; Admin not required):

```powershell
irm https://raw.githubusercontent.com/samjhill/wow-forever-couch/main/install.ps1 | iex
```

This clones/updates `~/Projects/wow-forever-couch`, runs `scripts/bootstrap-windows.ps1`, and installs a Scheduled Task.

### Prerequisites

- Forever already installable via Battle.net (script does **not** install Battle.net)
- **Git** and **Python 3** on PATH (bootstrap will try `winget` for `Git.Git` / `Python.Python.3.12` if missing)

## Forever path

Scripts look for `Wow.exe` under `_forever_`, typically:

`C:\Program Files (x86)\World of Warcraft\_forever_`

Also checks Program Files, LocalAppData, and common `D:`/`E:` layouts. Override if needed:

```powershell
$env:WOW_FOREVER = "D:\Games\World of Warcraft\_forever_"
```

If Forever is missing, bootstrap prints a clear message: install Forever via Battle.net, launch once (so `Interface\AddOns` exists), then re-run.

## What bootstrap does

When Forever is present:

1. Installs Immersion / Spoken + English voice packs + QoL set (`scripts/python/install_forever_stack.py`)
2. Syncs repo-owned addons (`PlaterQuestPin`, `CouchDictateRoute`) + SmartRebuff
3. Enables AddOns.txt entries after first login (`WTF\Account`)
4. Pins Spoken / Immersion prefs and graphics (`Config.wtf`)
5. Registers Scheduled Task **WoWForeverCouchUpdate** (every ~6h, full mode, including CurseForge addon refresh when Forever is quit)
6. Creates Start Menu + Desktop shortcut **Update WoW Forever Couch**

Manual sync anytime:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Projects\wow-forever-couch\scripts\apply-repo-updates.ps1" -Mode full
```

## Profiles / env

`profiles/windows.ps1` is auto-selected on Windows (`WOW_COUCH_DICTATION=0`, `WOW_COUCH_RESTORE_LIVE=0`). Live-setup restore remains opt-in and machine-specific — do not blindly copy bindings/macros across PCs.

## Steam on Windows

Native controller uses Blizzard’s controller UI and works without Steam. If you launch via Steam, existing Steam Input notes still apply; there is no separate Big Picture helper in v1.

## Phase 2 (not in this cut)

- Voice dictation (AutoHotkey v2 or SendKeys + Windows mic + whisper.cpp)
- Optional Steam Big Picture shortcut helper
- Broader winget dependency automation

## Linux / Deck unchanged

Steam Deck / Bazzite still use `install.sh` → `bootstrap-steamos.sh` and systemd timers. See [`steam-deck.md`](steam-deck.md).
