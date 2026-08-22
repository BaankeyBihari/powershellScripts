# @spec BOOT-012, BOOT-014
function Get-ProfileUpdate {
    <#
    .SYNOPSIS
    Re-downloads and re-runs install.ps1 to refresh installed packages and profile sections.
    .EXAMPLE
    Get-ProfileUpdate
    .EXAMPLE
    Get-ProfileUpdate -resourceUri ./default.json -installUri ./install.ps1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$resourceUri = "https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/default.json",
        [Parameter(Mandatory = $false)]
        [string]$installUri = "https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/install.ps1"
    )
    try {
        $installScriptContent = (Invoke-WebRequest -Uri $installUri -UseBasicParsing).Content
    }
    catch {
        Write-Error "Failed to download install.ps1 from '$installUri': $($_.Exception.Message)"
        return
    }
    try {
        $scriptBlock = [ScriptBlock]::Create($installScriptContent)
        & $scriptBlock -resourceUri $resourceUri -installUri $installUri
    }
    catch {
        Write-Error "install.ps1 failed while re-running: $($_.Exception.Message)"
        return
    }
}