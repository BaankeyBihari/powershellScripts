$hostname = hostname

$projectDir = "$env:localappdata/powershellScripts/"
try {
    New-Item -Type Directory -Path $projectDir -ErrorAction SilentlyContinue
}
catch {
    Write-Output "Already there"
}

$resourcePath = "$env:localappdata/powershellScripts/resource.json"

if($hostname.toLower().contains("dungeon")) {
    Write-Output "Match"
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/dungeon.json -OutFile $resourcePath
} else {
    Write-Output "No Match"
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/work.json -OutFile $resourcePath
}

$config = Get-Content $resourcePath -Raw | ConvertFrom-Json

function scoopManager() {
    try {
        Get-Command scoop -ErrorAction Stop
    }
    catch {
        Write-Output "Installing scoop"
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
        irm get.scoop.sh | iex
    }
}

function chocoManager() {
    Write-Output $config
}

function wingetManager() {
    Write-Output $config
}

foreach ($installer in $config.install) {
    Write-Output $installer
}