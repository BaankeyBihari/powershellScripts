function Get-ProfileUpdate {
    param(
        [Parameter(Mandatory = $false)]
        [string]$resourceUri = "https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/default.json",
        [Parameter(Mandatory = $false)]
        [string]$installUri = "https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/install.ps1"
    )
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($resourceUri) + " -resourceUri $resourceUri -installUri $installUri")
}