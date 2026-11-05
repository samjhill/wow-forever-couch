# Shared paths for wow-forever-couch on Windows (PowerShell).
# Dot-source from other scripts:
#   . "$PSScriptRoot\lib.ps1"

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:RepoRoot = if ($env:WOW_FOREVER_COUCH) {
    $env:WOW_FOREVER_COUCH
} else {
    (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}
$env:REPO_ROOT = $script:RepoRoot
$env:WOW_FOREVER_COUCH = $script:RepoRoot

function Get-CouchProfile {
    if ($env:WOW_COUCH_PROFILE) { return $env:WOW_COUCH_PROFILE }
    if ($IsWindows -or ($env:OS -match "Windows")) { return "windows" }
    return "default"
}

$env:WOW_COUCH_PROFILE = Get-CouchProfile
$profilePs1 = Join-Path $script:RepoRoot "profiles\$($env:WOW_COUCH_PROFILE).ps1"
if (Test-Path $profilePs1) {
    . $profilePs1
}

function Find-WowForeverRoot {
    if ($env:WOW_FOREVER -and (Test-Path (Join-Path $env:WOW_FOREVER "Wow.exe"))) {
        return (Resolve-Path $env:WOW_FOREVER).Path
    }

    $candidates = [System.Collections.Generic.List[string]]::new()
    foreach ($root in @(
        ${env:ProgramFiles(x86)},
        $env:ProgramFiles,
        $env:LOCALAPPDATA
    )) {
        if (-not $root) { continue }
        $candidates.Add((Join-Path $root "World of Warcraft\_forever_"))
        $candidates.Add((Join-Path $root "Battle.net\World of Warcraft\_forever_"))
    }
    # Common custom / secondary-drive layouts
    foreach ($drive in @("C:", "D:", "E:", "F:")) {
        $candidates.Add("$drive\World of Warcraft\_forever_")
        $candidates.Add("$drive\Games\World of Warcraft\_forever_")
        $candidates.Add("$drive\Program Files (x86)\World of Warcraft\_forever_")
    }
    # Proton/Wine-style path if someone dual-boots scripts against a Linux prefix mounted somehow
    $homeGames = Join-Path $HOME "Games\battlenet\pfx\drive_c\Program Files (x86)\World of Warcraft\_forever_"
    $candidates.Add($homeGames)

    foreach ($c in $candidates) {
        $exe = Join-Path $c "Wow.exe"
        if (Test-Path $exe) {
            return (Resolve-Path $c).Path
        }
    }

    # Slow fallback: search under Program Files for _forever_\Wow.exe (bounded)
    foreach ($base in @(${env:ProgramFiles(x86)}, $env:ProgramFiles)) {
        if (-not $base -or -not (Test-Path $base)) { continue }
        $hit = Get-ChildItem -Path $base -Filter "Wow.exe" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Directory.Name -eq "_forever_" } |
            Select-Object -First 1
        if ($hit) { return $hit.Directory.FullName }
    }
    return $null
}

$script:WowForever = Find-WowForeverRoot
if ($script:WowForever) {
    $env:WOW_FOREVER = $script:WowForever
} elseif (-not $env:WOW_FOREVER) {
    $env:WOW_FOREVER = Join-Path ${env:ProgramFiles(x86)} "World of Warcraft\_forever_"
}

$env:WOW_ADDONS = if ($env:WOW_ADDONS) { $env:WOW_ADDONS } else { Join-Path $env:WOW_FOREVER "Interface\AddOns" }
$env:WOW_COUCH_CONFIG = if ($env:WOW_COUCH_CONFIG) { $env:WOW_COUCH_CONFIG } else { Join-Path $script:RepoRoot "config" }

New-Item -ItemType Directory -Force -Path $env:WOW_COUCH_CONFIG | Out-Null

function Test-WowForeverInstalled {
    return (Test-Path (Join-Path $env:WOW_FOREVER "Wow.exe"))
}

function Test-WowRunning {
    return $null -ne (Get-Process -Name "Wow","WowClassic","WowT" -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Invoke-RepoPython {
    param(
        [Parameter(Mandatory = $true)][string[]]$PythonArgs
    )
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $cmd) { $cmd = Get-Command python3 -ErrorAction SilentlyContinue }
    $output = $null
    if ($cmd) {
        $output = & $cmd.Source @PythonArgs
    } else {
        $py = Get-Command py -ErrorAction SilentlyContinue
        if (-not $py) {
            throw "Python 3 is required (winget install Python.Python.3.12). Not found on PATH."
        }
        $output = & $py.Source -3 @PythonArgs
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Python exited with code $LASTEXITCODE ($($PythonArgs -join ' '))"
    }
    return $output
}

Write-Verbose "REPO_ROOT=$($script:RepoRoot) WOW_FOREVER=$($env:WOW_FOREVER) profile=$($env:WOW_COUCH_PROFILE)"
