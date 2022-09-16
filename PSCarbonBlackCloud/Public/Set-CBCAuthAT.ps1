function Set-CBCAuthAT {
    Param(
        [string]$CBC_AUTH_AT_SECTION
    )
    # $UseAT = Get-Variable -Name CBC_USE_AT
    if ($null -eq $UseAT) { 
        Set-Variable -Name CBC_USE_AT -Value $true -Scope Global
        Set-Variable -Name CBC_AUTH_AT_SECTION -Value $CBC_AUTH_AT_SECTION -Scope Global
        Set-Variable -Name CBC_USE_JWT -Value $false -Scope Global
    }
    else {
        Set-Variable -Name CBC_USE_AT -Value $false -Scope Global
    }

}