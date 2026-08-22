BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $installScriptPath = Join-Path $repoRoot 'install.ps1'

    # install.ps1 is never dot-sourced as a whole (it has real network/install/profile
    # side effects at the top level) so its embedded functions are extracted via AST
    # and defined in isolation instead.
    $installAst = [System.Management.Automation.Language.Parser]::ParseFile($installScriptPath, [ref]$null, [ref]$null)
    $testInstallExitCodeAst = $installAst.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Test-InstallExitCode'
        }, $true)
    . ([scriptblock]::Create($testInstallExitCodeAst.Extent.Text))
}

Describe 'install.ps1' {
    It 'has no PowerShell parse errors' {
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($installScriptPath, [ref]$null, [ref]$parseErrors) | Out-Null
        $parseErrors.Count | Should -Be 0
    }
}

Describe 'Test-InstallExitCode' {
    # @spec BOOT-013
    It 'returns true and does not warn when the exit code is 0' {
        $result = Test-InstallExitCode -ExitCode 0 -Source 'winget' -Item 'Some.App' -WarningVariable warnings -WarningAction SilentlyContinue
        $result | Should -Be $true
        $warnings | Should -BeNullOrEmpty
    }

    # @spec BOOT-013
    It 'returns false and warns with the item and source when the exit code is non-zero' {
        $result = Test-InstallExitCode -ExitCode 1 -Source 'scoop' -Item 'broken-pkg' -WarningVariable warnings -WarningAction SilentlyContinue
        $result | Should -Be $false
        $warnings | Should -Match 'broken-pkg'
        $warnings | Should -Match 'scoop'
    }
}
