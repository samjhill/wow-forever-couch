# Refresh Forever CurseForge addons (1.60.x files only).
# Skips when Forever is running. Runs from the daily scheduled task, not at game launch.
#Requires -Version 5.1
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib.ps1"

if (Test-WowRunning) {
    Write-Host "Forever is running — skip CurseForge addon update"
    exit 0
}

if (-not (Test-Path $env:WOW_ADDONS)) {
    Write-Host "Forever AddOns dir missing: $($env:WOW_ADDONS)"
    exit 2
}

$staging = Join-Path $env:WOW_COUCH_CONFIG "addons-staging"
New-Item -ItemType Directory -Force -Path $staging | Out-Null
$py = Join-Path $env:REPO_ROOT "scripts\python\update_curseforge_addons.py"
$updateArgs = @(
    $py,
    "--addons", $env:WOW_ADDONS,
    "--staging", $staging
)
$wtf = Join-Path $env:WOW_FOREVER "WTF\Account"
if (Test-Path $wtf) {
    $updateArgs += @("--wtf-account", $wtf)
}
Invoke-RepoPython $updateArgs
