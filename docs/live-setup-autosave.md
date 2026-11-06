# Periodic live-setup autosave

While you tune controller bindings and couch prefs, this Mac pulls a snapshot from the Bazzite box every **4 hours** and pushes `config/live-setup/` when it changed.

## How it works

1. launchd runs a wrapper outside `~/Documents` (macOS blocks LaunchAgents from reading that folder)
2. Work happens in the mirror clone `~/Projects/wow-forever-couch`
3. Script SSHs to `bazzite`, runs `snapshot-live-setup.sh`, commits + pushes when `config/live-setup/` changed

**Important:** Forever writes SavedVariables on logout/quit. Quit Forever (or relog) after binding changes so the next sync picks them up.

Pull in your Documents Cursor checkout when you want the latest: `git pull` in `Documents/opensource/wow-forever-couch`.

## Install / reload (this Mac)

```bash
mkdir -p ~/.cache/wow-forever-couch ~/Projects
# Mirror clone used by launchd (once)
[[ -d ~/Projects/wow-forever-couch/.git ]] || git clone https://github.com/samjhill/wow-forever-couch.git ~/Projects/wow-forever-couch

mkdir -p "$HOME/Library/Application Support/wow-forever-couch"
cp config/launchd/com.samjhill.wow-forever-couch-live-setup.plist ~/Library/LaunchAgents/
# Wrapper is installed by scripts/install-live-setup-autosave.sh
./scripts/install-live-setup-autosave.sh
```

Logs: `~/.cache/wow-forever-couch/live-setup-sync.*.log`

## Manual run

```bash
# From either checkout:
./scripts/auto-sync-live-setup.sh
# Or kick the agent:
launchctl kickstart -k gui/$(id -u)/com.samjhill.wow-forever-couch-live-setup
```

## Stop

```bash
launchctl bootout gui/$(id -u)/com.samjhill.wow-forever-couch-live-setup
```
