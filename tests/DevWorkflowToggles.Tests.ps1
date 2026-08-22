BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $repoRoot 'helpers/Start-ADBDaemon.ps1')
    . (Join-Path $repoRoot 'helpers/Switch-Kubernetes.ps1')
}

Describe 'Start-ADBDaemon' {
    # Wait-Job/Receive-Job require a real [Job] instance (Pester's mock proxies preserve
    # the real cmdlet's parameter types), so Start-Job is mocked to return a real,
    # fast/controllable job rather than a fake object — Wait-Job/Receive-Job run for real.
    AfterEach {
        Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
    }

    Context 'when the job is still running after the grace period (expected steady state)' {
        BeforeEach {
            # Created before Mock is registered so the real Start-Job cmdlet runs
            # unintercepted (calling it from inside the mock body recurses into the mock).
            $script:fakeJob = Start-Job -ScriptBlock { Start-Sleep -Seconds 30 }
            Mock Start-Job { $script:fakeJob }
        }

        # @spec TOGGLE-ADB-002
        It 'does not warn, and does not surface job output, when the job is still running' {
            $warnings = $null
            Start-ADBDaemon -WarningVariable warnings -WarningAction SilentlyContinue
            $warnings | Should -BeNullOrEmpty
        }
    }

    Context 'when the job ends early (e.g. adb missing from PATH)' {
        BeforeEach {
            $script:fakeJob = Start-Job -ScriptBlock { Write-Error 'simulated: adb not found' }
            Mock Start-Job { $script:fakeJob }
        }

        # @spec TOGGLE-ADB-002
        It 'warns that the job ended early instead of returning silently' {
            $warnings = $null
            Start-ADBDaemon -WarningVariable warnings -WarningAction SilentlyContinue
            $warnings | Should -Not -BeNullOrEmpty
        }

        # @spec TOGGLE-ADB-002
        It 'surfaces the job''s error output to the caller' {
            $errors = $null
            Start-ADBDaemon -WarningAction SilentlyContinue -ErrorVariable errors -ErrorAction SilentlyContinue
            ($errors | Where-Object { $_.ToString() -match 'simulated: adb not found' }) | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Switch-Kubernetes' {
    BeforeAll {
        # rdctl/docker are external CLIs (Rancher Desktop, Docker) that may not be
        # installed on the test machine/CI runner; stub them so Pester's Mock has a
        # real command to resolve and shadow.
        function rdctl {}
        function docker {}
    }

    Context 'when Docker becomes available immediately' {
        BeforeEach {
            Mock rdctl {
                if ($args[0] -eq 'list-settings') { '{"kubernetes":{"enabled":false}}' }
            }
            Mock docker { $global:LASTEXITCODE = 0 }
            Mock Start-Sleep { }
        }

        # @spec TOGGLE-K8S-001, TOGGLE-K8S-002
        It 'enables Kubernetes when it is currently disabled' {
            Switch-Kubernetes
            Should -Invoke rdctl -ParameterFilter { $args -join ' ' -eq 'set --kubernetes.enabled=true' }
        }

        # @spec TOGGLE-K8S-003
        It 'does not error when Docker reports available right away' {
            $errors = $null
            Switch-Kubernetes -ErrorVariable errors -ErrorAction SilentlyContinue
            $errors | Should -BeNullOrEmpty
        }
    }

    Context 'when Docker never becomes available within the timeout' {
        BeforeEach {
            Mock rdctl {
                if ($args[0] -eq 'list-settings') { '{"kubernetes":{"enabled":true}}' }
            }
            Mock docker { $global:LASTEXITCODE = 1 }
            Mock Start-Sleep { }
        }

        # @spec TOGGLE-K8S-004
        It 'stops polling and reports a timeout rather than looping indefinitely' {
            $errors = $null
            Switch-Kubernetes -TimeoutSeconds 0 -ErrorVariable errors -ErrorAction SilentlyContinue
            ($errors | Where-Object { $_.ToString() -match 'did not become available' }) | Should -Not -BeNullOrEmpty
        }
    }
}
