if ([Environment]::UserInteractive) {
    Import-Module posh-git
    oh-my-posh init pwsh --config paradox | Invoke-Expression
}
