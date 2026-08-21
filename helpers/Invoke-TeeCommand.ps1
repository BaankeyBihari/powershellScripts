function Invoke-TeeCommand {
    <#
    .SYNOPSIS
    Runs a command (bare words or a script block) and tees its combined output/error to both the console and a log file, like Unix `tee`.
    .EXAMPLE
    Invoke-TeeCommand docker ps
    .EXAMPLE
    Invoke-TeeCommand { docker ps -a }
    .EXAMPLE
    Invoke-TeeCommand -LogPath C:\temp\docker.log docker ps
    #>
    # Deliberately a basic function (no [CmdletBinding()]/[Parameter()]) so $args stays
    # the real automatic variable: splatting it as @args preserves "-flag value" pairs
    # from the original call. Declaring a typed/advanced parameter to collect the
    # remaining arguments instead collapses them to plain positional values on splat,
    # breaking forwarded flags like `docker ps -a`.
    $logPath = $null
    $rest = $args
    if ($args.Count -ge 2 -and $args[0] -eq '-LogPath') {
        $logPath = $args[1]
        $rest = @($args | Select-Object -Skip 2)
    }

    if (-not $logPath) {
        $prefix = if ($rest.Count -ge 1 -and $rest[0] -is [scriptblock]) {
            ($rest[0].ToString().Trim() -split '\s+')[0]
        }
        else {
            [string]$rest[0]
        }
        $safePrefix = ($prefix -replace '[^a-zA-Z0-9_-]', '').ToLower()
        if ([string]::IsNullOrWhiteSpace($safePrefix)) { $safePrefix = 'tee-log' }
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $randomSuffix = Get-Random -Minimum 1000 -Maximum 9999
        $logPath = Join-Path ([System.IO.Path]::GetTempPath()) "$safePrefix-$timestamp-$randomSuffix.log"
        Write-Warning "No -LogPath given; writing output to $logPath"
    }

    if ($rest.Count -eq 1 -and $rest[0] -is [scriptblock]) {
        & $rest[0] 2>&1 | Tee-Object -FilePath $logPath
    }
    else {
        $commandName, $commandArgs = $rest[0], @($rest | Select-Object -Skip 1)
        & $commandName @commandArgs 2>&1 | Tee-Object -FilePath $logPath
    }
}
