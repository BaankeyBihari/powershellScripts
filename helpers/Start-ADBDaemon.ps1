# @spec TOGGLE-ADB-001, TOGGLE-ADB-002
function Start-ADBDaemon {
    <#
    .SYNOPSIS
    Restarts the ADB server as a background job.
    .EXAMPLE
    Start-ADBDaemon
    #>
    [CmdletBinding()]
    param()

    $job = Start-Job {
        adb kill-server;
        adb -a -P 5037 nodaemon server;
    }
    # adb ... nodaemon server runs indefinitely once started, so a full Wait-Job would
    # block forever on success; a short grace period is enough to catch startup failures
    # (e.g. adb missing from PATH) without blocking on the long-running daemon itself.
    $null = Wait-Job -Job $job -Timeout 2
    if ($job.State -eq 'Running') {
        Write-Output "ADB daemon job started (Id: $($job.Id)) and is still running."
    }
    else {
        Write-Warning "Start-ADBDaemon's background job ended early (state: $($job.State)); adb may not be on PATH, or the daemon failed to start."
        Receive-Job -Job $job -ErrorAction Continue
    }
}