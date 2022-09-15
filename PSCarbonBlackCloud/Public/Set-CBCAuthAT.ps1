function Set-CBCAuthAT {
    Param(
        [string]$Section
    )
    # $UseAT = Get-Variable -Name CBC_USE_AT
    if ($null -eq $UseAT) { 
        Set-Variable -Name CBC_USE_AT -Value $true -Scope Global
        Set-Variable -Name Section -Value $Section -Scope Global
        Set-Variable -Name CBC_USE_JWT -Value $false -Scope Global
    }
    else {
        Set-Variable -Name CBC_USE_AT -Value $false -Scope Global
    }

}