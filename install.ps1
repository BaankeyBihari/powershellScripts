$hostname = hostname

$projectDir = "$env:localappdata/powershellScripts/"
try {
    New-Item -Type Directory -Path $projectDir -ErrorAction SilentlyContinue
}
catch {
    Write-Output "Already there"
}

$resourcePath = "$env:localappdata/powershellScripts/resource.json"
rm $resourcePath

if($hostname.toLower().contains("dungeon")) {
    Write-Output "Match"
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/dungeon.json -OutFile $resourcePath
} else {
    Write-Output "No Match"
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/others.json -OutFile $resourcePath
}

$config = Get-Content $resourcePath -Raw | ConvertFrom-Json

$scoopConfig
function scoopManager() {
    try {
        Get-Command scoop -ErrorAction Stop
    }
    catch {
        Write-Output "Installing scoop"
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
        irm get.scoop.sh | iex
    }
    foreach ($bucket in $scoopConfig.buckets) {
        if(Get-Member -inputobject $bucket -name "link" -Membertype Properties) {
            scoop bucket add $bucket.name $bucket.link
        } else {
            scoop bucket add $bucket.name
        }
    }
    foreach ($item in $scoopConfig.items) {
        scoop install $item
    }
}

$chocoConfig
function chocoManager() {
    try {
        Get-Command choco -ErrorAction Stop
    }
    catch {
        Write-Output "Installing choco"
        sudo iex "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    }
    foreach ($item in $chocoConfig.items) {
        sudo iex "choco install $item"
    }
}

$wingetConfig
function wingetManager() {
    foreach ($item in $chocoConfig.items) {
        winget install $item
    }
}

foreach ($installer in $config.install) {
    switch($installer.source) {
        "scoop" {
            Write-Output "Found Scoop"
            $scoopConfig = $installer
            scoopManager
            break
        }
        "choco" {
            Write-Output "Found Chocolatey"
            $chocoConfig = $installer
            chocoManager
            break
        }
        "winget" {
            Write-Output "Found Winget"
            $wingetConfig = $installer
            wingetManager
            break
        }
    }
}