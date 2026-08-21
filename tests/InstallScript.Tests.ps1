BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $installScriptPath = Join-Path $repoRoot 'install.ps1'
}

Describe 'install.ps1' {
    It 'has no PowerShell parse errors' {
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($installScriptPath, [ref]$null, [ref]$parseErrors) | Out-Null
        $parseErrors.Count | Should -Be 0
    }
}
