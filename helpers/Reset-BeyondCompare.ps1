function Reset-BeyondCompare {
    Get-ItemProperty -path 'HKCU:\Software\Scooter Software\Beyond Compare 4';
    Remove-ItemProperty -path 'HKCU:\Software\Scooter Software\Beyond Compare 4' -Name 'CacheID';
    Get-ItemProperty -path 'HKCU:\Software\Scooter Software\Beyond Compare 4';
}