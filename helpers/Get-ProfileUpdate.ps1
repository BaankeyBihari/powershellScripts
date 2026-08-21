function Get-ProfileUpdate {
    <#
    .SYNOPSIS
    Re-downloads and re-runs install.ps1 to refresh installed packages and profile sections.
    .EXAMPLE
    Get-ProfileUpdate
    .EXAMPLE
    Get-ProfileUpdate -resourceUri ./default.json -installUri ./install.ps1
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$resourceUri = "https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/default.json",
        [Parameter(Mandatory = $false)]
        [string]$installUri = "https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/install.ps1"
    )
    $scriptBlock = [ScriptBlock]::Create((New-Object System.Net.WebClient).DownloadString($installUri))
    & $scriptBlock -resourceUri $resourceUri -installUri $installUri
}