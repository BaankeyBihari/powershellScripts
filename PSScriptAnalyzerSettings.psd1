@{
    # Rules excluded because they conflict with patterns this repo uses intentionally:
    #  - install.ps1 runs user-supplied config snippets from default.json via Invoke-Expression by design.
    #  - helpers/*.ps1 are thin wrappers around external tools (adb, scoop) that PSScriptAnalyzer
    #    misreads as positional-parameter cmdlet calls, and around state-changing actions that don't
    #    warrant -WhatIf/-Confirm support for one-shot personal utility functions.
    ExcludeRules = @(
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPositionalParameters',
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
