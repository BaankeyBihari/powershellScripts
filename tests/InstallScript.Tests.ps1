BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $installScriptPath = Join-Path $repoRoot 'install.ps1'

    # install.ps1 is never dot-sourced as a whole (it has real network/install/profile
    # side effects at the top level) so its embedded functions are extracted via AST
    # and defined in isolation instead.
    $installAst = [System.Management.Automation.Language.Parser]::ParseFile($installScriptPath, [ref]$null, [ref]$null)
    foreach ($functionName in @('Test-InstallExitCode', 'Resolve-PlanItem', 'Format-FailureLabel')) {
        $ast = $installAst.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName
            }, $true)
        . ([scriptblock]::Create($ast.Extent.Text))
    }
}

Describe 'install.ps1' {
    # @spec QUALITY-007
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

Describe 'Resolve-PlanItem' {
    # @spec BOOT-015
    It 'extracts id as Item and name as Name from an {id, name} object entry' {
        $entry = [PSCustomObject]@{ id = 'ALCPU.CoreTemp'; name = 'Core Temp' }
        $result = Resolve-PlanItem -Entry $entry
        $result.Item | Should -Be 'ALCPU.CoreTemp'
        $result.Name | Should -Be 'Core Temp'
    }

    # @spec BOOT-016
    It 'falls back to the raw string for both Item and Name when the entry is a flat string (scoop)' {
        $result = Resolve-PlanItem -Entry 'sudo'
        $result.Item | Should -Be 'sudo'
        $result.Name | Should -Be 'sudo'
    }
}

Describe 'Format-FailureLabel' {
    # @spec BOOT-017
    It 'formats as "Name (Item)" when Name differs from Item' {
        Format-FailureLabel -Item 'ALCPU.CoreTemp' -Name 'Core Temp' | Should -Be 'Core Temp (ALCPU.CoreTemp)'
    }

    # @spec BOOT-017
    It 'formats as just Item when Name equals Item (scoop fallback case)' {
        Format-FailureLabel -Item 'sudo' -Name 'sudo' | Should -Be 'sudo'
    }
}
