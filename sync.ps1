#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

if (Test-Path $PROFILE) {
    Copy-Item -Path $PROFILE -Destination (Join-Path $repoRoot 'windows\Microsoft.PowerShell_profile.ps1') -Force
    Write-Host "Pulled: windows\Microsoft.PowerShell_profile.ps1"
}

$vscodeSystem = "$env:APPDATA\Code\User\settings.json"
$vscodeRepo = Join-Path $repoRoot 'vscode\settings.json'
$vscodeLocal = Join-Path $repoRoot 'vscode\settings.local.json'
$vscodePrivatePrefixes = @('remote.SSH.')

if (Test-Path $vscodeSystem) {
    $raw = Get-Content $vscodeSystem -Raw | ConvertFrom-Json
    $public = [ordered]@{}
    $private = [ordered]@{}
    foreach ($prop in $raw.PSObject.Properties) {
        $isPrivate = $false
        foreach ($prefix in $vscodePrivatePrefixes) {
            if ($prop.Name.StartsWith($prefix)) { $isPrivate = $true; break }
        }
        if ($isPrivate) { $private[$prop.Name] = $prop.Value } else { $public[$prop.Name] = $prop.Value }
    }
    ([pscustomobject]$public | ConvertTo-Json -Depth 50) | Set-Content -Path $vscodeRepo -Encoding utf8
    Write-Host "Pulled: $vscodeRepo ($($public.Count) public keys)"
    if ($private.Count -gt 0) {
        ([pscustomobject]$private | ConvertTo-Json -Depth 50) | Set-Content -Path $vscodeLocal -Encoding utf8
        Write-Host "Local:  $vscodeLocal ($($private.Count) private keys, gitignored)"
    }
    elseif (Test-Path $vscodeLocal) {
        Remove-Item $vscodeLocal
    }
}

$termSystem = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$termRepo = Join-Path $repoRoot 'windows\windows-terminal-settings.json'
$termLocal = Join-Path $repoRoot 'windows\windows-terminal-private-profiles.local.json'

if (Test-Path $termSystem) {
    $settings = Get-Content $termSystem -Raw | ConvertFrom-Json
    $privateProfiles = @()
    $publicProfiles = @()
    foreach ($p in $settings.profiles.list) {
        $cmd = $p.PSObject.Properties['commandline']
        if ($cmd -and $cmd.Value -match '^\s*ssh\s') {
            $privateProfiles += $p
        }
        else {
            $publicProfiles += $p
        }
    }

    $settings.profiles.list = $publicProfiles
    ($settings | ConvertTo-Json -Depth 50) | Set-Content -Path $termRepo -Encoding utf8
    Write-Host "Pulled: $termRepo ($($publicProfiles.Count) public profiles)"

    if ($privateProfiles.Count -gt 0) {
        (,$privateProfiles | ConvertTo-Json -Depth 50) | Set-Content -Path $termLocal -Encoding utf8
        Write-Host "Local:  $termLocal ($($privateProfiles.Count) private profiles, gitignored)"
    }
    elseif (Test-Path $termLocal) {
        Remove-Item $termLocal
    }
}
else {
    Write-Warning "System file missing, skipping: $termSystem"
}
