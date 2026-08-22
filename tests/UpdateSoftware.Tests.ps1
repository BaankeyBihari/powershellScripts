BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $repoRoot 'helpers/Update-Software.ps1')

    # Pre-shadow scoop/uv with plain functions before Pester ever mocks them. On a machine
    # where scoop is actually installed, the real `scoop` command resolves to an ExternalScript
    # (scoop.ps1), and mocking that command type directly has been observed to corrupt other
    # mocks' closures; mocking a plain function avoids the issue entirely and keeps behavior
    # identical regardless of what's really installed on the machine running the tests.
    function global:scoop {}
    function global:uv {}
}

Describe 'Update-Software' {
    BeforeEach {
        $script:callLog = [System.Collections.Generic.List[string]]::new()
        Mock Write-Host { $script:callLog.Add("HOST:$Object") }
        Mock winget { $script:callLog.Add("winget:$($args -join ' ')") }
        Mock scoop { $script:callLog.Add("scoop:$($args -join ' ')") }
        Mock uv { $script:callLog.Add("uv:$($args -join ' ')") }
    }

    # @spec SWUPDATE-001
    It 'accepts no parameters beyond PowerShell''s common parameters' {
        $custom = (Get-Command Update-Software).Parameters.Keys |
            Where-Object { $_ -notin [System.Management.Automation.PSCmdlet]::CommonParameters -and $_ -notin [System.Management.Automation.PSCmdlet]::OptionalCommonParameters }
        $custom | Should -BeNullOrEmpty
    }

    Context 'when scoop and uv are both found on PATH' {
        BeforeEach {
            # Safe, non-recursive default for any Get-Command call this test doesn't care about
            # (e.g. incidental calls from Pester/PowerShell internals) — never forward to the real
            # cmdlet from inside its own mock, which recurses until the call stack overflows.
            Mock Get-Command { $null }
            Mock Get-Command { $true } -ParameterFilter { $Name -eq 'scoop' }
            Mock Get-Command { $true } -ParameterFilter { $Name -eq 'uv' }
        }

        # @spec SWUPDATE-002
        It 'runs winget upgrade --all' {
            Update-Software
            Should -Invoke winget -ParameterFilter { ($args -join ' ') -eq 'upgrade --all' }
        }

        # @spec SWUPDATE-003
        It 'runs scoop update followed by scoop update --all' {
            Update-Software
            Should -Invoke scoop -ParameterFilter { ($args -join ' ') -eq 'update' }
            Should -Invoke scoop -ParameterFilter { ($args -join ' ') -eq 'update --all' }
        }

        # @spec SWUPDATE-005
        It 'runs uv tool upgrade --all' {
            Update-Software
            Should -Invoke uv -ParameterFilter { ($args -join ' ') -eq 'tool upgrade --all' }
        }

        # @spec SWUPDATE-007
        It 'runs winget, then scoop, then uv, in that order' {
            Update-Software
            $order = $script:callLog | Where-Object { $_ -match '^(winget|scoop|uv):' } | ForEach-Object { ($_ -split ':')[0] }
            ($order | Select-Object -Unique) | Should -Be @('winget', 'scoop', 'uv')
        }

        # @spec SWUPDATE-008
        It 'writes a banner before each of the three steps, in source order' {
            Update-Software
            $banners = $script:callLog | Where-Object { $_ -like 'HOST:*' }
            $banners.Count | Should -Be 3
            $banners[0] | Should -Match 'winget'
            $banners[1] | Should -Match 'scoop'
            $banners[2] | Should -Match 'uv'
        }

        # @spec SWUPDATE-002, SWUPDATE-003, SWUPDATE-005
        It 'does not warn when both optional tools are present' {
            $warnings = $null
            Update-Software -WarningVariable warnings -WarningAction SilentlyContinue
            $warnings | Should -BeNullOrEmpty
        }
    }

    Context 'when scoop is not found on PATH' {
        BeforeEach {
            Mock Get-Command { $null }
            Mock Get-Command { $true } -ParameterFilter { $Name -eq 'uv' }
        }

        # @spec SWUPDATE-004
        It 'warns instead of running scoop' {
            $warnings = $null
            Update-Software -WarningVariable warnings -WarningAction SilentlyContinue
            ($warnings | Where-Object { $_.ToString() -match 'scoop' }) | Should -Not -BeNullOrEmpty
            Should -Invoke scoop -Times 0 -Exactly
        }

        # @spec SWUPDATE-004, SWUPDATE-009
        It 'still runs the uv step afterward' {
            Update-Software -WarningAction SilentlyContinue
            Should -Invoke uv -Times 1 -Exactly -ParameterFilter { ($args -join ' ') -eq 'tool upgrade --all' }
        }
    }

    Context 'when uv is not found on PATH' {
        BeforeEach {
            Mock Get-Command { $null }
            Mock Get-Command { $true } -ParameterFilter { $Name -eq 'scoop' }
        }

        # @spec SWUPDATE-006
        It 'warns instead of running uv, without throwing' {
            $warnings = $null
            $errors = $null
            Update-Software -WarningVariable warnings -WarningAction SilentlyContinue -ErrorVariable errors -ErrorAction SilentlyContinue
            ($warnings | Where-Object { $_.ToString() -match 'uv' }) | Should -Not -BeNullOrEmpty
            $errors | Should -BeNullOrEmpty
            Should -Invoke uv -Times 0 -Exactly
        }
    }

    Context 'when the winget step fails' {
        BeforeEach {
            Mock Get-Command { $null }
            Mock Get-Command { $true } -ParameterFilter { $Name -eq 'scoop' }
            Mock Get-Command { $true } -ParameterFilter { $Name -eq 'uv' }
            Mock winget { $script:callLog.Add("winget:$($args -join ' ')"); $global:LASTEXITCODE = 1 }
        }

        # @spec SWUPDATE-009
        It 'still runs the scoop and uv steps afterward' {
            Update-Software -WarningAction SilentlyContinue
            Should -Invoke scoop -Times 1 -Exactly -ParameterFilter { ($args -join ' ') -eq 'update' }
            Should -Invoke uv -Times 1 -Exactly -ParameterFilter { ($args -join ' ') -eq 'tool upgrade --all' }
        }
    }
}
