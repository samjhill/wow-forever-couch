# Copy/update repo-owned Forever addons into Interface/AddOns (Windows).
#Requires -Version 5.1
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib.ps1"

if (-not (Test-WowForeverInstalled)) {
    Write-Error "Forever AddOns dir missing (Wow.exe not found under $($env:WOW_FOREVER)). Install Forever via Battle.net, launch once, then re-run."
}

$addons = $env:WOW_ADDONS
New-Item -ItemType Directory -Force -Path $addons | Out-Null

foreach ($name in @("ConsolePortCouch", "CouchDictateRoute", "PlaterQuestPin", "CouchBuffReminder")) {
    $src = Join-Path $env:REPO_ROOT "addons\$name"
    if (-not (Test-Path $src)) {
        Write-Host "skip missing repo addon: $name"
        continue
    }
    $dest = Join-Path $addons $name
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Copy-Item -Recurse -Force $src $dest
    Write-Host "synced $name → $dest"
}

# Optional SelfBuffs via shared CurseForge fetch
$staging = Join-Path $env:WOW_COUCH_CONFIG "addons-staging"
New-Item -ItemType Directory -Force -Path $staging | Out-Null
$fetchPy = Join-Path $env:REPO_ROOT "scripts\python\curseforge_fetch.py"
$unzipPy = Join-Path $env:REPO_ROOT "scripts\python\unzip_addons.py"
try {
    $zipOut = Invoke-RepoPython @($fetchPy, "--project", "1718593", "--staging", $staging)
    $zipPath = if ($zipOut -is [array]) { "$($zipOut[-1])".Trim() } else { "$zipOut".Trim() }
    if ($zipPath -and (Test-Path -LiteralPath $zipPath)) {
        Invoke-RepoPython @($unzipPy, $zipPath, "--dest", $addons) | Out-Null
    }
} catch {
    Write-Host "SelfBuffs optional install skipped: $_"
}

$wtfAccount = Join-Path $env:WOW_FOREVER "WTF\Account"
if (Test-Path $wtfAccount) {
    Invoke-RepoPython @(
        (Join-Path $env:REPO_ROOT "scripts\python\enable_addons.py"),
        "--wtf-account", $wtfAccount
    ) | Out-Null
}

Write-Host "Repo addon sync done."
