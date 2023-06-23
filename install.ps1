#Requires -Version 7

param(
    [Parameter(Mandatory = $false)]
    [string]$resourceUri = "https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/default.json",
    [Parameter(Mandatory = $false)]
    [string]$installUri = "https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/install.ps1"
)

$projectDir = "$env:localappdata/powershellScripts/"
try {
    New-Item -Type Directory -Path $projectDir -ErrorAction SilentlyContinue
}
catch {
    Write-Output "$projectDir already exsists."
}

$resourcePath = "$env:localappdata/powershellScripts/resource.json"
$installPath = "$env:localappdata/powershellScripts/install.ps1"
Remove-Item $resourcePath -ErrorAction SilentlyContinue
Remove-Item $installPath -ErrorAction SilentlyContinue

Write-Output "Downloading Install File from $installUri to $installPath"
Invoke-WebRequest -Uri "${installUri}" -OutFile $installPath

Write-Output "Downloading Resource File from $resourceUri to $resourcePath"
Invoke-WebRequest -Uri "${resourceUri}" -OutFile $resourcePath

# Config for Installers
$config = Get-Content $resourcePath -Raw | ConvertFrom-Json

# Install Winget Apps
$wingetConfig
function wingetInstaller() {
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
        }
        else {
            Write-Output "Skipping installation of $item"
        }
    }
}

# Install Scoop Apps
$scoopConfig
function scoopInstaller() {
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
function chocoInstaller() {
    try {
        Get-Command choco -ErrorAction Stop
    }
    catch {
        Write-Output "Installing choco"
        winget install -e --id Chocolatey.Chocolatey
    }
    foreach ($item in $chocoConfig.items) {
        sudo Invoke-Expression "choco install $item"
    }
    foreach ($item in $chocoConfig.pinned) {
        sudo Invoke-Expression "choco pin -n $item"
    }
}

# Execute from admin command line
$adminCommandLineConfig
function adminCommandLineLauncher() {
    foreach ($item in $adminCommandLineConfig.items) {
        sudo Invoke-Expression "$item"
    }
}

# Execute from command line
$commandLineConfig
function commandLineLauncher() {
    foreach ($item in $commandLineConfig.items) {
        Invoke-Expression "$item"
    }
}

foreach ($installer in $config.install) {
    switch ($installer.source) {
        "scoop" {
            Write-Output "Found Scoop"
            $scoopConfig = $installer
            scoopInstaller
            break
        }
        "choco" {
            Write-Output "Found Chocolatey"
            $chocoConfig = $installer
            chocoInstaller
            break
        }
        "winget" {
            Write-Output "Found Winget"
            $wingetConfig = $installer
            wingetInstaller
            break
        }
        "adminCommandLine" {
            Write-Output "Found Admin Command Line"
            $adminCommandLineConfig = $installer
            adminCommandLineLauncher
            break
        }
        "commandLine" {
            Write-Output "Found Command Line"
            $commandLineConfig = $installer
            commandLineLauncher
            break
        }
    }
}

# Check and delete old sections
if ( Test-Path $Profile.CurrentUserAllHosts ) {
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

# Write new sections
$profileValues
function profileWriter() {
    $sectionName = $profileValues.sectionName
    $value = $profileValues.value
    switch ($profileValues.type) {
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

foreach ($profileItem in $config.profile) {
    $profileValues = $profileItem
    profileWriter
}

