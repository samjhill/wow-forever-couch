# Install a user-scoped Scheduled Task that refreshes Forever CurseForge addons once a day.
#Requires -Version 5.1
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib.ps1"

$taskName = "WoWForeverCurseForgeUpdate"
$update = Join-Path $env:REPO_ROOT "scripts\update-curseforge-addons.ps1"
$psExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"

$arg = "-NoProfile -ExecutionPolicy Bypass -File `"$update`""
$action = New-ScheduledTaskAction -Execute $psExe -Argument $arg -WorkingDirectory $env:REPO_ROOT
$trigger = New-ScheduledTaskTrigger -Daily -At 4:00am
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
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Refresh WoW Forever CurseForge addons daily at 04:00. Skips while Forever is running." |
    Out-Null

Write-Host "Scheduled Task installed: $taskName (daily 04:00)"
Write-Host "Manual run: powershell -NoProfile -ExecutionPolicy Bypass -File `"$update`""
Get-ScheduledTask -TaskName $taskName | Format-List TaskName, State, Description
