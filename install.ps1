#Requires -Version 7

$hostname = hostname

$projectDir = "$env:localappdata/powershellScripts/"
try {
    New-Item -Type Directory -Path $projectDir -ErrorAction SilentlyContinue
}
catch {
    Write-Output "$projectDir already exsists."
}

$resourcePath = "$env:localappdata/powershellScripts/resource.json"
Remove-Item $resourcePath

if ($hostname.toLower().contains("dungeon")) {
    Write-Output "Downloading Dungeon Config"
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/dungeon.json -OutFile $resourcePath
}
else {
    Write-Output "Downloading Other Config"
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
        Invoke-RestMethod get.scoop.sh | Invoke-Expression
    }
    foreach ($bucket in $scoopConfig.buckets) {
        if (Get-Member -inputobject $bucket -name "link" -Membertype Properties) {
            scoop bucket add $bucket.name $bucket.link
        }
        else {
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
        sudo Invoke-Expression "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    }
    foreach ($item in $chocoConfig.items) {
        sudo Invoke-Expression "choco install $item"
    }
    foreach ($item in $chocoConfig.pinned) {
        sudo Invoke-Expression "choco pin -n $item"
    }
}

$wingetConfig
function wingetManager() {
    foreach ($item in $wingetConfig.items) {
        $wingetInstalledTest = winget list $item
        $wingetInstallationFound = $wingetInstalledTest | ForEach-Object {
            if ($_ -eq "No installed package found matching input criteria.") {
                Write-Output $_
            }
        }
        if ($wingetInstallationFound -eq "No installed package found matching input criteria.") {
            Write-Output "Installing $item using winget"
            winget install -e --id $item
        } else {
            Write-Output "Skipping installation of $item"
        }
    }
}

$adminCommandLineConfig
function adminCommandLineManager() {
    foreach ($item in $adminCommandLineConfig.items) {
        sudo Invoke-Expression "$item"
    }
}

$commandLineConfig
function commandLineManager() {
    foreach ($item in $commandLineConfig.items) {
        Invoke-Expression "$item"
    }
}

foreach ($installer in $config.install) {
    switch ($installer.source) {
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
        "adminCommandLine" {
            Write-Output "Found Admin Command Line"
            $adminCommandLineConfig = $installer
            adminCommandLineManager
            break
        }
        "commandLine" {
            Write-Output "Found Command Line"
            $commandLineConfig = $installer
            commandLineManager
            break
        }
    }
}

if ( Test-Path $Profile.CurrentUserAllHosts ) {
    # Check and delete old aliases
    foreach ($profileItem in $config.profile) {
        $sectionName = $profileItem.sectionName
        $CurrentContent = Get-Content $Profile.CurrentUserAllHosts
        $ContainsWord = $CurrentContent | ForEach-Object { $_ -match "#---Begin Section: $sectionName" }
        if ($containsWord -contains $true) {
            $saveInstance = $true
            $UpdatedContent = Get-Content -Path $Profile.CurrentUserAllHosts |
            ForEach-Object {
                if ( $_ -match ( '^' + [regex]::Escape( "#---Begin Section: $sectionName---" ) ) ) {
                    $saveInstance = $false
                }
                elseif ( $_ -match ( '^' + [regex]::Escape( "#---End Section: $sectionName---" ) ) ) {
                    $saveInstance = $true
                }
                elseif ( $saveInstance ) {
                    $_
                }
            }
            $UpdatedContent | Out-File -FilePath $Profile.CurrentUserAllHosts -Encoding Default -Force
        }
    }
}

foreach ($profileItem in $config.profile) {
    $sectionName = $profileItem.sectionName
    $value = $profileItem.value
    switch ($profileItem.type) {
        "link" {
            "#---Begin Section: $sectionName---" >> $Profile.CurrentUserAllHosts
            (Invoke-webrequest -URI "$value").Content >> $Profile.CurrentUserAllHosts
            "#---End Section: $sectionName---" >> $Profile.CurrentUserAllHosts
            break
        }
        "content" {
            "#---Begin Section: $sectionName---" >> $Profile.CurrentUserAllHosts
            "$value" >> $Profile.CurrentUserAllHosts
            "#---End Section: $sectionName---" >> $Profile.CurrentUserAllHosts
            break
        }
    }
}