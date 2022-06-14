function Get-ChocoUpgrade {
    sudo Invoke-Expression "\
        choco feature enable -n=allowGlobalConfirmation;\
        choco upgrade all;\
        choco feature disable -n=allowGlobalConfirmation;\
    "
}