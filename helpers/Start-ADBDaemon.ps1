function Start-ADBDaemon {
    Start-Job {
        adb kill-server;
        adb -a -P 5037 nodaemon server;
    }
}