BeforeDiscovery {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $helperCases = Get-ChildItem -Path (Join-Path $repoRoot 'helpers') -Filter '*.ps1' | ForEach-Object {
        @{
            Path         = $_.FullName
            FileName     = $_.Name
            FunctionName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        }
    }
}

Describe 'helpers/<_.FileName>' -ForEach $helperCases {
    It 'has no PowerShell parse errors' {
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($_.Path, [ref]$null, [ref]$parseErrors) | Out-Null
        $parseErrors.Count | Should -Be 0
    }

    It "defines a function named '<_.FunctionName>' matching its filename" {
        . $_.Path
        Get-Command $_.FunctionName -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}
