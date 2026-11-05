# Curl-friendly entrypoint for native Windows Battle.net Forever installs.
#
#   irm https://raw.githubusercontent.com/samjhill/wow-forever-couch/main/install.ps1 | iex
#
#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$RepoUrl = if ($env:WOW_COUCH_REPO_URL) { $env:WOW_COUCH_REPO_URL } else { "https://github.com/samjhill/wow-forever-couch.git" }
$Branch = if ($env:WOW_COUCH_BRANCH) { $env:WOW_COUCH_BRANCH } else { "main" }
$Dest = if ($env:WOW_COUCH_HOME) { $env:WOW_COUCH_HOME } else { Join-Path $env:USERPROFILE "Projects\wow-forever-couch" }

Write-Host "=== WoW Forever Couch installer (Windows) ==="
Write-Host "Installing into: $Dest"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Host "git missing — installing Git.Git via winget…"
        & $winget.Source install --id Git.Git -e --accept-source-agreements --accept-package-agreements | Out-Null
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required. Install from https://git-scm.com/download/win then re-run."
}

$parent = Split-Path $Dest -Parent
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }

if (Test-Path (Join-Path $Dest ".git")) {
    Write-Host "Existing checkout found — updating $Branch…"
    git -C $Dest fetch origin $Branch 2>$null
    if ($LASTEXITCODE -ne 0) { git -C $Dest fetch origin | Out-Null }
    git -C $Dest checkout $Branch 2>$null | Out-Null
    git -C $Dest pull --ff-only origin $Branch
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Fast-forward failed; continuing with local tree."
    }
} elseif (Test-Path $Dest) {
    throw "Directory exists but is not a git repo: $Dest. Move it aside or set `$env:WOW_COUCH_HOME."
} else {
    git clone --branch $Branch --single-branch $RepoUrl $Dest
    if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
}

Write-Host ""
Write-Host "Running Windows bootstrap (addons, pins, Scheduled Task)…"
& (Join-Path $Dest "scripts\bootstrap-windows.ps1")
