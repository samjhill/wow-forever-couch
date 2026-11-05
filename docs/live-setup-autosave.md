# Periodic live-setup autosave

While you tune ConsolePort bindings and couch prefs, this Mac pulls a snapshot from the Bazzite box every **4 hours** and pushes `config/live-setup/` when it changed.

## How it works

1. launchd runs `scripts/auto-sync-live-setup.sh`
2. Script SSHs to `bazzite`, runs `snapshot-live-setup.sh`, rsyncs into the repo
3. If only `config/live-setup/` changed → commit + push to `main`

**Important:** Forever writes SavedVariables on logout/quit. Quit Forever (or relog) after binding changes so the next sync picks them up. Mid-session snapshots only see the last flush.

## Install / reload (this Mac)

```bash
mkdir -p ~/.cache/wow-forever-couch
cp config/launchd/com.samjhill.wow-forever-couch-live-setup.plist ~/Library/LaunchAgents/
launchctl bootout gui/$(id -u)/com.samjhill.wow-forever-couch-live-setup 2>/dev/null || true
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.samjhill.wow-forever-couch-live-setup.plist
launchctl kickstart -k gui/$(id -u)/com.samjhill.wow-forever-couch-live-setup
```

Logs: `~/.cache/wow-forever-couch/live-setup-sync.*.log`

## Manual run

```bash
./scripts/auto-sync-live-setup.sh
```

## Stop

```bash
launchctl bootout gui/$(id -u)/com.samjhill.wow-forever-couch-live-setup
```
