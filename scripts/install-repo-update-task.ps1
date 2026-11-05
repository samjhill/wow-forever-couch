# Install a user-scoped Scheduled Task that pulls this repo and applies full updates every 6h.
#Requires -Version 5.1
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib.ps1"

$taskName = "WoWForeverCouchUpdate"
$apply = Join-Path $env:REPO_ROOT "scripts\apply-repo-updates.ps1"
$psExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"

$arg = "-NoProfile -ExecutionPolicy Bypass -File `"$apply`" -Mode full"
$action = New-ScheduledTaskAction -Execute $psExe -Argument $arg -WorkingDirectory $env:REPO_ROOT
$triggerBoot = New-ScheduledTaskTrigger -AtLogOn
$triggerRepeat = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddMinutes(5) `
    -RepetitionInterval (New-TimeSpan -Hours 6) `
    -RepetitionDuration (New-TimeSpan -Days 3650)
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger @($triggerBoot, $triggerRepeat) `
    -Settings $settings `
    -Principal $principal `
    -Description "Pull wow-forever-couch and apply safe updates (every 6h)" |
    Out-Null

Write-Host "Scheduled Task installed: $taskName"
Write-Host "Manual run: powershell -NoProfile -ExecutionPolicy Bypass -File `"$apply`" -Mode full"
Get-ScheduledTask -TaskName $taskName | Format-List TaskName, State, Description
