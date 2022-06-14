function Get-ProfileUpdate {
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://gist.github.com/BaankeyBihari/813847f34dc5a18fafa7df773bc2a284/raw'));
}