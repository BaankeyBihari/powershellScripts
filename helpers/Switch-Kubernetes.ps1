# @spec TOGGLE-K8S-001, TOGGLE-K8S-002, TOGGLE-K8S-003, TOGGLE-K8S-004
function Switch-Kubernetes {
    <#
    .SYNOPSIS
    Toggles the Kubernetes backend in Rancher Desktop via rdctl (enables it if currently disabled, disables it if currently enabled), then waits (up to a timeout) for Docker to come back online.
    .EXAMPLE
    Switch-Kubernetes
    .EXAMPLE
    Switch-Kubernetes -TimeoutSeconds 300
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Switch-Kubernetes names the Kubernetes backend it toggles, not a plural collection.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'This is an interactive console helper; its status messages are meant for the terminal, not the pipeline.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 120
    )

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

    Write-Host "Waiting for Docker to become available (timeout: ${TimeoutSeconds}s)..."
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ($true) {
        docker info *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Docker is back online!"
            return
        }
        if ((Get-Date) -ge $deadline) {
            Write-Error "Docker did not become available within $TimeoutSeconds seconds after toggling Kubernetes."
            return
        }
        Start-Sleep -Seconds 2
    }
}
