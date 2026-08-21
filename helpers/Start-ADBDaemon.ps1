function Start-ADBDaemon {
    <#
    .SYNOPSIS
    Restarts the ADB server as a background job.
    .EXAMPLE
    Start-ADBDaemon
    #>
    Start-Job {
        adb kill-server;
        adb -a -P 5037 nodaemon server;
    }
}