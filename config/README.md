# Config

- **`live-setup/`** — committed snapshot of the working Forever couch prefs (AddOns list, ConsolePort / Immersion / ForeverVO / QoL SavedVariables, bindings cache, Config.wtf). Refresh with `./scripts/snapshot-live-setup.sh` on the play box; apply with `./scripts/restore-live-setup.sh`. Autosaved every 4h from this Mac via launchd — [`docs/live-setup-autosave.md`](../docs/live-setup-autosave.md).
- **`launchd/`** — LaunchAgent plist for that autosave.
- **`steam-input/`** — Steam Input notes / share codes.
- Other runtime files (dictation status, staging zips, backups) are gitignored.
