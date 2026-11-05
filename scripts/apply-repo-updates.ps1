# Pull latest main (ff-only) and apply safe couch updates (Windows).
#Requires -Version 5.1
param(
    [ValidateSet("quick", "full")]
    [string]$Mode = $(if ($env:WOW_COUCH_UPDATE_MODE) { $env:WOW_COUCH_UPDATE_MODE } else { "quick" }),
    [string]$Branch = $(if ($env:WOW_COUCH_BRANCH) { $env:WOW_COUCH_BRANCH } else { "main" })
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib.ps1"

$prefix = "[apply-repo-updates]"
function Log([string]$msg) { Write-Host "$prefix $msg" }

$lockDir = Join-Path $env:TEMP "wow-forever-couch"
New-Item -ItemType Directory -Force -Path $lockDir | Out-Null
$lockFile = Join-Path $lockDir "apply-repo-updates.lock"
try {
    $lockStream = [System.IO.File]::Open($lockFile, "OpenOrCreate", "ReadWrite", "None")
} catch {
    Log "another apply is running — skip"
    exit 0
}

try {
    Set-Location $env:REPO_ROOT
    if ($env:WOW_COUCH_SKIP_GIT -ne "1") {
        if (Test-Path (Join-Path $env:REPO_ROOT ".git")) {
            git fetch origin $Branch 2>$null
            if ($LASTEXITCODE -ne 0) { git fetch origin 2>$null | Out-Null }
            git pull --ff-only origin $Branch
            if ($LASTEXITCODE -ne 0) {
                Log "git pull --ff-only failed — leave tree alone"
            } else {
                Log "pulled origin/$Branch"
            }
        } else {
            Log "not a git checkout — skip pull"
        }
    }

    $running = Test-WowRunning
    if ($running) { Log "Forever appears running" }

    if (Test-WowForeverInstalled) {
        & "$PSScriptRoot\sync-repo-addons.ps1"
    } else {
        Log "Forever missing — skip addon sync"
    }

    if ($Mode -eq "full" -and (Test-WowForeverInstalled)) {
        if (-not $running) {
            Invoke-RepoPython @(
                (Join-Path $env:REPO_ROOT "scripts\python\pin_prefs.py"),
                "--forever", $env:WOW_FOREVER,
                "--couch-config", $env:WOW_COUCH_CONFIG,
                "--voiceover"
            )
        }
        Invoke-RepoPython @(
            (Join-Path $env:REPO_ROOT "scripts\python\pin_prefs.py"),
            "--forever", $env:WOW_FOREVER,
            "--couch-config", $env:WOW_COUCH_CONFIG,
            "--graphics"
        )
        if ($env:WOW_COUCH_RESTORE_LIVE -eq "1") {
            if ($running) {
                Log "WOW_COUCH_RESTORE_LIVE=1 but Forever is running — skip restore"
            } else {
                $restore = Join-Path $env:REPO_ROOT "scripts\restore-live-setup.sh"
                Log "live-setup restore is bash-oriented; copy config\live-setup manually or use Git Bash if needed ($restore)"
            }
        }
    }

    Log "done (mode=$Mode profile=$($env:WOW_COUCH_PROFILE))"
} finally {
    $lockStream.Close()
}
