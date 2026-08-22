# @spec BCOMPARE-001, BCOMPARE-002, BCOMPARE-003, BCOMPARE-004
function Reset-BeyondCompare {
    <#
    .SYNOPSIS
    Clears the Beyond Compare 4 trial CacheID registry value to reset its trial period.
    .EXAMPLE
    Reset-BeyondCompare
    #>
    $keyPath = 'HKCU:\Software\Scooter Software\Beyond Compare 4'

    if (-not (Test-Path -Path $keyPath)) {
        Write-Warning "Beyond Compare 4 registry key not found at $keyPath; nothing to reset (is it installed?)."
        return
    }

    $before = Get-ItemProperty -Path $keyPath
    $before

    if (-not ($before.PSObject.Properties.Name -contains 'CacheID')) {
        Write-Warning "CacheID value not present under $keyPath; trial tracking already appears reset."
        return
    }

    Remove-ItemProperty -Path $keyPath -Name 'CacheID'
    Get-ItemProperty -Path $keyPath
}