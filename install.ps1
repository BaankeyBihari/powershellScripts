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

function Test-PackageInstalled($source, $item) {
    switch ($source) {
        "winget" {
            $result = winget list --id $item --exact --accept-source-agreements
            return -not ($result -match "No installed package found matching input criteria.")
        }
        "msstore" {
            $result = winget list --id $item --exact --source msstore --accept-source-agreements
            return -not ($result -match "No installed package found matching input criteria.")
        }
        "scoop" {
            if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                return $false
            }
            $result = scoop list $item 6>$null
            return [bool]($result | Where-Object { $_.Name -eq $item })
        }
        default {
            return $false
        }
    }
}

# Build a plan across winget/msstore/scoop: what's already there vs what's missing,
# split into required (always installed) and optional (gated behind a prompt)
$plan = @()
foreach ($installer in $config.install) {
    if ($installer.source -notin @("winget", "msstore", "scoop")) {
        continue
    }
    foreach ($item in $installer.items) {
        $plan += [PSCustomObject]@{ Source = $installer.source; Item = $item; Required = $true }
    }
    foreach ($item in $installer.optional) {
        $plan += [PSCustomObject]@{ Source = $installer.source; Item = $item; Required = $false }
    }
}

Write-Output "Detecting what's already installed..."
foreach ($entry in $plan) {
    $entry | Add-Member -NotePropertyName AlreadyInstalled -NotePropertyValue (Test-PackageInstalled $entry.Source $entry.Item)
}

$alreadyInstalled = @($plan | Where-Object { $_.AlreadyInstalled })
$missingRequired = @($plan | Where-Object { -not $_.AlreadyInstalled -and $_.Required })
$missingOptional = @($plan | Where-Object { -not $_.AlreadyInstalled -and -not $_.Required })

Write-Output ""
Write-Output "=== Detected ==="
Write-Output "Already installed: $($alreadyInstalled.Count)"
Write-Output "Needs installation (required): $($missingRequired.Count)"
$missingRequired | ForEach-Object { Write-Output "  - $($_.Item) [$($_.Source)]" }
Write-Output "Needs installation (optional): $($missingOptional.Count)"
$missingOptional | ForEach-Object { Write-Output "  - $($_.Item) [$($_.Source)]" }
Write-Output ""

$toInstall = @() + $missingRequired
if ($missingOptional.Count -gt 0) {
    $response = Read-Host "Install $($missingOptional.Count) optional package(s) too? [y/N]"
    if ($response -match "^[Yy]") {
        $toInstall += $missingOptional
    }
    else {
        Write-Output "Skipping optional packages; installing required only."
    }
}

$total = $toInstall.Count
$i = 0
foreach ($entry in $toInstall) {
    $i++
    Write-Output "[$i/$total] Installing $($entry.Item) via $($entry.Source)..."
    switch ($entry.Source) {
        "winget" {
            winget install -e --id $entry.Item --accept-source-agreements --accept-package-agreements
        }
        "msstore" {
            winget install -e --source msstore --id $entry.Item --accept-source-agreements --accept-package-agreements
        }
        "scoop" {
            if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                Write-Output "Installing scoop"
                Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
                Invoke-RestMethod get.scoop.sh | Invoke-Expression
            }
            scoop install $entry.Item
        }
    }
}
if ($total -gt 0) {
    Write-Output "Done: $i/$total installed."
}

# Scoop buckets are cheap/idempotent, so these are added regardless of the required/optional choice
foreach ($installer in $config.install) {
    if ($installer.source -eq "scoop" -and $installer.buckets) {
        if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
            Write-Output "Installing scoop"
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
            Invoke-RestMethod get.scoop.sh | Invoke-Expression
        }
        $existingBuckets = @(scoop bucket list | Select-Object -ExpandProperty Name)
        foreach ($bucket in $installer.buckets) {
            if ($existingBuckets -contains $bucket.name) {
                continue
            }
            if (Get-Member -inputobject $bucket -name "link" -Membertype Properties) {
                scoop bucket add $bucket.name $bucket.link
            }
            else {
                scoop bucket add $bucket.name
            }
        }
    }
}

# Execute from admin command line
foreach ($installer in $config.install) {
    if ($installer.source -eq "adminCommandLine") {
        foreach ($item in $installer.items) {
            sudo Invoke-Expression "$item"
        }
    }
}

# Execute from command line
foreach ($installer in $config.install) {
    if ($installer.source -eq "commandLine") {
        foreach ($item in $installer.items) {
            Invoke-Expression "$item"
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
