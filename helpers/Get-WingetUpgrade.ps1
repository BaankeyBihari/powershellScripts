function Get-WingetUpgrade {
    <#
    .SYNOPSIS
    Lists (and offers to upgrade) all winget packages with available updates.
    .EXAMPLE
    Get-WingetUpgrade
    #>
    winget upgrade --all
}