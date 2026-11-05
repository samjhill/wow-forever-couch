# Defaults for native Windows Battle.net / Forever installs.
# Sourced by scripts/lib.ps1 when WOW_COUCH_PROFILE=windows.

$env:WOW_COUCH_PROFILE = "windows"
$env:WOW_COUCH_DICTATION = if ($env:WOW_COUCH_DICTATION) { $env:WOW_COUCH_DICTATION } else { "0" }
$env:WOW_COUCH_RESTORE_LIVE = if ($env:WOW_COUCH_RESTORE_LIVE) { $env:WOW_COUCH_RESTORE_LIVE } else { "0" }
