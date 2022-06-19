function Get-ProfileUpdate {
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/install.ps1'));
}