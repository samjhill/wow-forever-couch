# One-shot Windows bootstrap for native Battle.net Forever installs.
#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$DefaultClone = Join-Path $env:USERPROFILE "Projects\wow-forever-couch"
$RepoUrl = if ($env:WOW_COUCH_REPO_URL) { $env:WOW_COUCH_REPO_URL } else { "https://github.com/samjhill/wow-forever-couch.git" }

function Resolve-Repo {
    $here = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    if (Test-Path (Join-Path $here "scripts\lib.ps1")) { return $here }
    if (Test-Path (Join-Path $DefaultClone "scripts\lib.ps1")) { return $DefaultClone }
    return $null
}

$Repo = Resolve-Repo
if (-not $Repo) {
    Write-Host "Cloning $RepoUrl → $DefaultClone"
    New-Item -ItemType Directory -Force -Path (Split-Path $DefaultClone -Parent) | Out-Null
    git clone $RepoUrl $DefaultClone
    if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
    $Repo = $DefaultClone
}

. (Join-Path $Repo "scripts\lib.ps1")

Write-Host "=== wow-forever-couch Windows bootstrap ==="
Write-Host "REPO_ROOT=$($env:REPO_ROOT)"
Write-Host "profile=$($env:WOW_COUCH_PROFILE)"
Write-Host "WOW_FOREVER=$($env:WOW_FOREVER)"

# Ensure git + python are present (winget when available; do not fail hard)
function Ensure-Cmd([string]$Name, [string]$WingetId) {
    if (Get-Command $Name -ErrorAction SilentlyContinue) { return }
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Host "Installing $WingetId via winget…"
        & $winget.Source install --id $WingetId -e --accept-source-agreements --accept-package-agreements 2>$null | Out-Null
    }
}

Ensure-Cmd "git" "Git.Git"
Ensure-Cmd "python" "Python.Python.3.12"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required. Install from https://git-scm.com/download/win then re-run."
}
try {
    Invoke-RepoPython @("-c", "print('ok')") | Out-Null
} catch {
    throw "Python 3 is required (winget install Python.Python.3.12). $_"
}

if (Test-WowForeverInstalled) {
    Write-Host "=== Forever client found — installing addons ==="
    $stackPy = Join-Path $env:REPO_ROOT "scripts\python\install_forever_stack.py"
    $staging = Join-Path $env:WOW_COUCH_CONFIG "addons-staging"
    try {
        Invoke-RepoPython @(
            $stackPy,
            "--forever", $env:WOW_FOREVER,
            "--repo", $env:REPO_ROOT,
            "--staging", $staging
        )
    } catch {
        Write-Host "Addon stack install reported errors: $_"
    }

    & (Join-Path $env:REPO_ROOT "scripts\sync-repo-addons.ps1")

    $wtfAccount = Join-Path $env:WOW_FOREVER "WTF\Account"
    if (Test-Path $wtfAccount) {
        Invoke-RepoPython @(
            (Join-Path $env:REPO_ROOT "scripts\python\enable_addons.py"),
            "--wtf-account", $wtfAccount
        )
        Invoke-RepoPython @(
            (Join-Path $env:REPO_ROOT "scripts\python\pin_prefs.py"),
            "--forever", $env:WOW_FOREVER,
            "--couch-config", $env:WOW_COUCH_CONFIG,
            "--voiceover"
        )
    } else {
        Write-Host "No WTF\Account yet — log into Forever once, then re-run bootstrap or:"
        Write-Host "  .\scripts\sync-repo-addons.ps1"
        Write-Host "  (enable + pin run automatically after first login)"
    }

    Invoke-RepoPython @(
        (Join-Path $env:REPO_ROOT "scripts\python\pin_prefs.py"),
        "--forever", $env:WOW_FOREVER,
        "--couch-config", $env:WOW_COUCH_CONFIG,
        "--graphics"
    )

    if ($env:WOW_COUCH_RESTORE_LIVE -eq "1") {
        Write-Host "WOW_COUCH_RESTORE_LIVE=1: live-setup restore is opt-in and machine-specific."
        Write-Host "Copy files from config\live-setup into your Forever WTF tree carefully, or use Git Bash with restore-live-setup.sh."
    }
} else {
    Write-Host "=== Forever not installed yet ==="
    Write-Host "Install Forever via Battle.net (native Windows), launch once so Interface\AddOns exists, then re-run this bootstrap."
    Write-Host "Expected Wow.exe under: $($env:WOW_FOREVER)"
    Write-Host "Or set `$env:WOW_FOREVER to your _forever_ folder before re-running."
}

Write-Host "=== Auto-update Scheduled Task ==="
& (Join-Path $env:REPO_ROOT "scripts\install-repo-update-task.ps1")

# Start Menu + Desktop shortcut
$shortcutName = "Update WoW Forever Couch.lnk"
$apply = Join-Path $env:REPO_ROOT "scripts\apply-repo-updates.ps1"
$psExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
$wsh = New-Object -ComObject WScript.Shell

function New-CouchShortcut([string]$Dir) {
    New-Item -ItemType Directory -Force -Path $Dir | Out-Null
    $path = Join-Path $Dir $shortcutName
    $sc = $wsh.CreateShortcut($path)
    $sc.TargetPath = $psExe
    $sc.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$apply`" -Mode full"
    $sc.WorkingDirectory = $env:REPO_ROOT
    $sc.Description = "Pull wow-forever-couch and apply couch updates"
    $sc.Save()
    Write-Host "Shortcut: $path"
}

$programs = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
New-CouchShortcut $programs
New-CouchShortcut ([Environment]::GetFolderPath("Desktop"))

Write-Host ""
Write-Host "=== Done ==="
Write-Host "Docs: $($env:REPO_ROOT)\docs\windows.md"
Write-Host "Sync now:  powershell -NoProfile -ExecutionPolicy Bypass -File `"$apply`" -Mode full"
Write-Host "Dictation is Linux-only for now (Phase 2 on Windows)."
