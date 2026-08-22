BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $repoRoot 'helpers/Invoke-TeeCommand.ps1')
}

Describe 'Invoke-TeeCommand' {
    # Invoke-TeeCommand deliberately has no [CmdletBinding()] (see its inline comment),
    # so -ErrorAction/-ErrorVariable/-WarningVariable common parameters aren't available —
    # errors/warnings are captured here via stream redirection (2>&1 / 3>&1) instead.

    # @spec TEE-005
    It 'reports a clear error when called with no arguments' {
        $result = Invoke-TeeCommand 2>&1
        $result | Should -Match 'requires a command to run'
    }

    # @spec TEE-005
    It 'reports a clear error when only -LogPath is given with no command' {
        $result = Invoke-TeeCommand -LogPath (Join-Path $TestDrive 'x.log') 2>&1
        $result | Should -Match 'requires a command to run after -LogPath'
    }

    # @spec TEE-005
    It 'does not reach the default-log-path logic when called with no arguments' {
        $result = Invoke-TeeCommand 2>&1 3>&1
        ($result -join ' ') | Should -Not -Match 'No -LogPath given'
    }

    It 'still runs the wrapped command and writes the log when given a command' {
        $logPath = Join-Path $TestDrive 'happy.log'
        Invoke-TeeCommand -LogPath $logPath Write-Output 'hello-tee' | Out-Null
        Get-Content $logPath -Raw | Should -Match 'hello-tee'
    }
}
