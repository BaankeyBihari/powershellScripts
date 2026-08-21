function Switch-Kubernetes {
    <#
    .SYNOPSIS
    Toggles the Kubernetes backend in Rancher Desktop via rdctl (enables it if currently disabled, disables it if currently enabled), then waits for Docker to come back online.
    .EXAMPLE
    Switch-Kubernetes
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Switch-Kubernetes names the Kubernetes backend it toggles, not a plural collection.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'This is an interactive console helper; its status messages are meant for the terminal, not the pipeline.')]
    param()

    $currentSettings = rdctl list-settings | ConvertFrom-Json
    $currentlyEnabled = $currentSettings.kubernetes.enabled

    if ($currentlyEnabled) {
        Write-Host "Kubernetes is currently ENABLED. Disabling now..."
        rdctl set --kubernetes.enabled=false
    }
    else {
        Write-Host "Kubernetes is currently DISABLED. Enabling now..."
        rdctl set --kubernetes.enabled=true
    }

    Write-Host "Waiting for Docker to become available..."
    while ($true) {
        docker info *> $null
        if ($LASTEXITCODE -eq 0) {
            break
        }
        Start-Sleep -Seconds 2
    }
    Write-Host "Docker is back online!"
}
