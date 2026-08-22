BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $repoRoot 'helpers/Reset-BeyondCompare.ps1')
    $keyPath = 'HKCU:\Software\Scooter Software\Beyond Compare 4'
}

Describe 'Reset-BeyondCompare' {
    # Registry cmdlets are mocked with -ParameterFilter scoped to the exact hardcoded
    # key path, so this never touches the real Beyond Compare registry state.

    Context 'when the registry key does not exist' {
        BeforeEach {
            Mock Test-Path { $false } -ParameterFilter { $Path -eq $keyPath }
            Mock Remove-ItemProperty { } -ParameterFilter { $Path -eq $keyPath }
        }

        # @spec BCOMPARE-004
        It 'warns with a clear message instead of a raw registry error' {
            $warnings = Reset-BeyondCompare 3>&1 | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }
            $warnings | Should -Match 'registry key not found'
        }

        # @spec BCOMPARE-004
        It 'does not attempt to remove CacheID' {
            Reset-BeyondCompare 3>&1 | Out-Null
            Should -Invoke Remove-ItemProperty -Times 0
        }
    }

    Context 'when the key exists but CacheID is already gone' {
        BeforeEach {
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $keyPath }
            Mock Get-ItemProperty { [PSCustomObject]@{ PSPath = $keyPath } } -ParameterFilter { $Path -eq $keyPath }
            Mock Remove-ItemProperty { } -ParameterFilter { $Path -eq $keyPath }
        }

        # @spec BCOMPARE-004
        It 'warns with a clear message instead of a raw registry error' {
            $warnings = Reset-BeyondCompare 3>&1 | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }
            $warnings | Should -Match 'CacheID value not present'
        }

        # @spec BCOMPARE-004
        It 'does not attempt to remove CacheID again' {
            Reset-BeyondCompare 3>&1 | Out-Null
            Should -Invoke Remove-ItemProperty -Times 0
        }
    }

    Context 'when the key and CacheID both exist (happy path)' {
        BeforeEach {
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $keyPath }
            # Get-ItemProperty is called twice per Reset-BeyondCompare run (before and
            # after removal); the call counter lets the mock reflect CacheID's removal
            # on the second call instead of returning the same object both times.
            $script:getItemPropertyCallCount = 0
            Mock Get-ItemProperty {
                $script:getItemPropertyCallCount++
                if ($script:getItemPropertyCallCount -eq 1) {
                    [PSCustomObject]@{ PSPath = $keyPath; CacheID = 'some-cached-id' }
                } else {
                    [PSCustomObject]@{ PSPath = $keyPath }
                }
            } -ParameterFilter { $Path -eq $keyPath }
            Mock Remove-ItemProperty { } -ParameterFilter { $Path -eq $keyPath -and $Name -eq 'CacheID' }
        }

        # @spec BCOMPARE-001
        It 'prints the current registry value before making any change' {
            $output = Reset-BeyondCompare | Where-Object { $_ -isnot [System.Management.Automation.WarningRecord] }
            $output[0].CacheID | Should -Be 'some-cached-id'
        }

        # @spec BCOMPARE-002
        It 'removes the CacheID value' {
            Reset-BeyondCompare | Out-Null
            Should -Invoke Remove-ItemProperty -Times 1 -ParameterFilter { $Path -eq $keyPath -and $Name -eq 'CacheID' }
        }

        # @spec BCOMPARE-003
        It 'prints the resulting registry value after removing CacheID' {
            $output = Reset-BeyondCompare | Where-Object { $_ -isnot [System.Management.Automation.WarningRecord] }
            $output[1].PSObject.Properties.Name | Should -Not -Contain 'CacheID'
        }

        # @spec BCOMPARE-004
        It 'does not warn' {
            $warnings = Reset-BeyondCompare 3>&1 | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }
            $warnings | Should -BeNullOrEmpty
        }
    }
}
