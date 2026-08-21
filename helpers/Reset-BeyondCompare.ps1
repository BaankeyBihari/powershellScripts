function Reset-BeyondCompare {
    <#
    .SYNOPSIS
    Clears the Beyond Compare 4 trial CacheID registry value to reset its trial period.
    .EXAMPLE
    Reset-BeyondCompare
    #>
    Get-ItemProperty -path 'HKCU:\Software\Scooter Software\Beyond Compare 4';
    Remove-ItemProperty -path 'HKCU:\Software\Scooter Software\Beyond Compare 4' -Name 'CacheID';
    Get-ItemProperty -path 'HKCU:\Software\Scooter Software\Beyond Compare 4';
}