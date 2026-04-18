#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupDir = Join-Path $repoRoot ".backup\$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$links = @(
    @{
        Source = Join-Path $repoRoot 'windows\Microsoft.PowerShell_profile.ps1'
        Target = $PROFILE
    },
    @{
        Source = Join-Path $repoRoot 'windows\windows-terminal-settings.json'
        Target = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    }
)

foreach ($link in $links) {
    $src = $link.Source
    $dst = $link.Target

    if (-not (Test-Path $src)) {
        Write-Warning "Source missing, skipping: $src"
        continue
    }

    $dstDir = Split-Path -Parent $dst
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }

    if (Test-Path $dst) {
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        Copy-Item -Path $dst -Destination (Join-Path $backupDir (Split-Path -Leaf $dst)) -Force
    }

    Copy-Item -Path $src -Destination $dst -Force
    Write-Host "Installed: $dst"
}

if (Test-Path $backupDir) {
    Write-Host ""
    Write-Host "Previous files backed up to: $backupDir"
}
