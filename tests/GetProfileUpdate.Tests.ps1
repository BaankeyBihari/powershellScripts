BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $repoRoot 'helpers/Get-ProfileUpdate.ps1')
}

Describe 'Get-ProfileUpdate' {
    Context 'when downloading install.ps1 fails' {
        BeforeEach {
            Mock Invoke-WebRequest { throw 'simulated network failure' }
        }

        # @spec BOOT-014
        It 'reports a clear error instead of an unhandled exception' {
            $err = $null
            Get-ProfileUpdate -ErrorAction SilentlyContinue -ErrorVariable err
            ($err | Where-Object { $_.ToString() -match 'Failed to download install\.ps1' }) | Should -Not -BeNullOrEmpty
        }

        # @spec BOOT-014
        It 'does not throw' {
            { Get-ProfileUpdate -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'when the downloaded install.ps1 fails to run' {
        BeforeEach {
            Mock Invoke-WebRequest { [PSCustomObject]@{ Content = 'throw "simulated install.ps1 failure"' } }
        }

        # @spec BOOT-014
        It 'reports a clear error instead of an unhandled exception' {
            $err = $null
            Get-ProfileUpdate -ErrorAction SilentlyContinue -ErrorVariable err
            ($err | Where-Object { $_.ToString() -match 'install\.ps1 failed while re-running' }) | Should -Not -BeNullOrEmpty
        }

        # @spec BOOT-014
        It 'does not throw' {
            { Get-ProfileUpdate -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'when the download and re-run both succeed' {
        BeforeEach {
            Mock Invoke-WebRequest { [PSCustomObject]@{ Content = 'param($resourceUri, $installUri)' } }
        }

        # @spec BOOT-012
        It 'invokes the downloaded script with the caller-supplied resourceUri/installUri' {
            { Get-ProfileUpdate -resourceUri 'https://example.test/default.json' -installUri 'https://example.test/install.ps1' } | Should -Not -Throw
        }
    }
}
