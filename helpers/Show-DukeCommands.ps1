function Show-DukeCommands {
    <#
    .SYNOPSIS
    Lists all functions this repo has spliced into the current PowerShell profile, with their description and usage.
    .EXAMPLE
    Show-DukeCommands
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Show-DukeCommands intentionally lists a plural set of commands.')]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ProfilePath = $Profile.CurrentUserAllHosts
    )

    if (-not (Test-Path $ProfilePath)) {
        Write-Warning "No profile found at $ProfilePath"
        return
    }

    $sectionNames = Get-Content $ProfilePath |
    Select-String -Pattern '^#---Begin Section: (.+)---$' |
    ForEach-Object { $_.Matches[0].Groups[1].Value }

    foreach ($name in $sectionNames) {
        $command = Get-Command -Name $name -CommandType Function -ErrorAction SilentlyContinue
        if (-not $command) {
            continue
        }

        $help = Get-Help -Name $name -ErrorAction SilentlyContinue
        $synopsis = if ($help -and $help.Synopsis -and $help.Synopsis.Trim() -ne $name) {
            $help.Synopsis.Trim()
        }
        else {
            "(no description available)"
        }

        Write-Host ""
        Write-Host $name -ForegroundColor Cyan
        Write-Host "  $synopsis"
        Write-Host "  Usage: $((Get-Command -Name $name -Syntax).Trim())" -ForegroundColor DarkGray
    }
}
