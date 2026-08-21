function Start-ClaudeHeadroom {
    <#
    .SYNOPSIS
    Launches claude with ANTHROPIC_BASE_URL pointed at a locally running Headroom proxy.
    .EXAMPLE
    Start-ClaudeHeadroom
    #>
    $headroomUrl = "http://127.0.0.1:8787"

    try {
        Invoke-WebRequest -Uri "$headroomUrl/health" -UseBasicParsing -TimeoutSec 2 | Out-Null
    }
    catch {
        Write-Error "Headroom proxy is not reachable at $headroomUrl/health.`nStart it via Docker with: headroom install apply --preset persistent-docker`nOr run it in another shell with: headroom proxy"
        return
    }

    $command = '$env:ANTHROPIC_BASE_URL = ''{0}''; claude' -f $headroomUrl
    pwsh -NoProfile -Command $command
}
