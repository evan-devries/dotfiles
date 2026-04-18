#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$pairs = @(
    @{
        System = $PROFILE
        Repo   = Join-Path $repoRoot 'windows\Microsoft.PowerShell_profile.ps1'
    },
    @{
        System = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        Repo   = Join-Path $repoRoot 'windows\windows-terminal-settings.json'
    }
)

foreach ($pair in $pairs) {
    if (-not (Test-Path $pair.System)) {
        Write-Warning "System file missing, skipping: $($pair.System)"
        continue
    }
    Copy-Item -Path $pair.System -Destination $pair.Repo -Force
    Write-Host "Pulled: $($pair.Repo)"
}
