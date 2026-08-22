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
    # @spec QUALITY-005
    It 'has no PowerShell parse errors' {
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($_.Path, [ref]$null, [ref]$parseErrors) | Out-Null
        $parseErrors.Count | Should -Be 0
    }

    # @spec QUALITY-006
    It "defines a function named '<_.FunctionName>' matching its filename" {
        . $_.Path
        Get-Command $_.FunctionName -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    # @spec QUALITY-011
    It "has a .SYNOPSIS comment-based help block" {
        . $_.Path
        $synopsis = (Get-Help $_.FunctionName -ErrorAction SilentlyContinue).Synopsis
        $synopsis = if ($synopsis) { $synopsis.Trim() } else { '' }
        $synopsis | Should -Not -BeNullOrEmpty -Because "helpers/$($_.FileName) should start with a <# .SYNOPSIS ... #> comment-based help block (see AGENTS.md)"
        $synopsis | Should -Not -Be $_.FunctionName -Because "Get-Help falls back to the bare function name when no .SYNOPSIS is present"
    }
}
