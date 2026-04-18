#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupDir = Join-Path $repoRoot ".backup\$(Get-Date -Format 'yyyyMMdd-HHmmss')"

function Backup-And-Write {
    param([string]$Destination, [string]$Content)

    $dstDir = Split-Path -Parent $Destination
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }
    if (Test-Path $Destination) {
        if (-not (Test-Path $script:backupDir)) {
            New-Item -ItemType Directory -Path $script:backupDir -Force | Out-Null
        }
        Copy-Item -Path $Destination -Destination (Join-Path $script:backupDir (Split-Path -Leaf $Destination)) -Force
    }
    Set-Content -Path $Destination -Value $Content -Encoding utf8 -NoNewline
    Write-Host "Installed: $Destination"
}

$psProfileSource = Join-Path $repoRoot 'windows\Microsoft.PowerShell_profile.ps1'
if (Test-Path $psProfileSource) {
    Backup-And-Write -Destination $PROFILE -Content (Get-Content $psProfileSource -Raw)
}

$vscodeRepo = Join-Path $repoRoot 'vscode\settings.json'
$vscodeLocal = Join-Path $repoRoot 'vscode\settings.local.json'
$vscodeTarget = "$env:APPDATA\Code\User\settings.json"
if (Test-Path $vscodeRepo) {
    $merged = [ordered]@{}
    (Get-Content $vscodeRepo -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $merged[$_.Name] = $_.Value }
    if (Test-Path $vscodeLocal) {
        (Get-Content $vscodeLocal -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $merged[$_.Name] = $_.Value }
        Write-Host "Merged VS Code private keys from local overlay"
    }
    $json = [pscustomobject]$merged | ConvertTo-Json -Depth 50
    Backup-And-Write -Destination $vscodeTarget -Content $json
}

$termRepo = Join-Path $repoRoot 'windows\windows-terminal-settings.json'
$termLocal = Join-Path $repoRoot 'windows\windows-terminal-private-profiles.local.json'
$termTarget = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $termRepo) {
    $termSettings = Get-Content $termRepo -Raw | ConvertFrom-Json
    if (Test-Path $termLocal) {
        $privateProfiles = Get-Content $termLocal -Raw | ConvertFrom-Json
        if ($privateProfiles) {
            $termSettings.profiles.list = @($termSettings.profiles.list) + @($privateProfiles)
            Write-Host "Merged $(@($privateProfiles).Count) private profile(s) from local overlay"
        }
    }
    $json = $termSettings | ConvertTo-Json -Depth 50
    Backup-And-Write -Destination $termTarget -Content $json
}

$extensionsFile = Join-Path $repoRoot 'vscode\extensions.txt'
if (Test-Path $extensionsFile) {
    $code = Get-Command code -ErrorAction SilentlyContinue
    if ($code) {
        $installed = & code --list-extensions
        $wanted = Get-Content $extensionsFile | Where-Object { $_ -and -not $_.StartsWith('#') }
        $missing = $wanted | Where-Object { $installed -notcontains $_ }
        foreach ($ext in $missing) {
            Write-Host "Installing VS Code extension: $ext"
            & code --install-extension $ext | Out-Null
        }
        if (-not $missing) {
            Write-Host "VS Code extensions already up to date"
        }
    }
    else {
        Write-Warning "'code' CLI not on PATH; skipping VS Code extension install"
    }
}

if (Test-Path $backupDir) {
    Write-Host ""
    Write-Host "Previous files backed up to: $backupDir"
}
