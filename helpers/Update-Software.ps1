# @spec SWUPDATE-001, SWUPDATE-002, SWUPDATE-003, SWUPDATE-004, SWUPDATE-005, SWUPDATE-006, SWUPDATE-007, SWUPDATE-008, SWUPDATE-009
function Update-Software {
    <#
    .SYNOPSIS
    Updates every package source this repo installs from: winget, scoop (apps and buckets), and uv-managed tools.
    .EXAMPLE
    Update-Software
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'This is an interactive console helper; its per-source banners are meant for the terminal, not the pipeline.')]
    [CmdletBinding()]
    param()

    Write-Host 'Updating winget packages...'
    winget upgrade --all

    Write-Host 'Updating scoop packages...'
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        scoop update
        scoop update --all
    }
    else {
        Write-Warning 'scoop not found on PATH; skipping scoop update.'
    }

    Write-Host 'Updating uv-managed tools...'
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        uv tool upgrade --all
    }
    else {
        Write-Warning 'uv not found on PATH; skipping uv tool upgrade.'
    }
}
