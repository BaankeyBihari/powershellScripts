BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $configPath = Join-Path $repoRoot 'default.json'
    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    $knownInstallSources = @('winget', 'msstore', 'scoop', 'adminCommandLine', 'commandLine')
}

Describe 'default.json' {
    It 'is valid JSON with top-level install and profile arrays' {
        $config.install | Should -Not -BeNullOrEmpty
        $config.profile | Should -Not -BeNullOrEmpty
    }

    Context 'install entries' {
        It 'only use known sources' {
            foreach ($entry in $config.install) {
                $entry.source | Should -BeIn $knownInstallSources
            }
        }

        It 'give winget/msstore/scoop entries an items property' {
            foreach ($entry in $config.install | Where-Object { $_.source -in @('winget', 'msstore', 'scoop') }) {
                $entry.PSObject.Properties.Name | Should -Contain 'items' -Because "source '$($entry.source)' should declare an items array (can be empty)"
            }
        }
    }

    Context 'profile entries' {
        It 'have a sectionName, a known type, and a value' {
            foreach ($entry in $config.profile) {
                $entry.sectionName | Should -Not -BeNullOrEmpty
                $entry.type | Should -BeIn @('link', 'content')
                $entry.PSObject.Properties.Name | Should -Contain 'value'
            }
        }

        It 'point link entries under helpers/ at a file that exists and defines a matching function' {
            $helperLinks = $config.profile | Where-Object { $_.type -eq 'link' -and $_.value -match '/helpers/([^/]+\.ps1)$' }
            foreach ($entry in $helperLinks) {
                $null = $entry.value -match '/helpers/([^/]+\.ps1)$'
                $fileName = $Matches[1]
                $helperPath = Join-Path $repoRoot "helpers/$fileName"
                Test-Path $helperPath | Should -BeTrue -Because "profile entry '$($entry.sectionName)' links to helpers/$fileName"
                if (Test-Path $helperPath) {
                    (Get-Content $helperPath -Raw) | Should -Match "function\s+$([regex]::Escape($entry.sectionName))\b" -Because "helpers/$fileName should define function $($entry.sectionName)"
                }
            }
        }
    }
}
