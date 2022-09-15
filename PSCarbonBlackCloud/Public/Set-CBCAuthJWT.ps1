function Set-CBCAuthJWT {
    Process {
        # $UseJwt = Get-Variable -Name CBC_USE_JWT
        if ($null -eq $CBC_USE_JWT) { 
            Set-Variable -Name CBC_USE_JWT -Value $true -Scope Global
            Set-Variable -Name CBC_USE_AT -Value $false -Scope Global
        }
        else {
            Set-Variable -Name CBC_USE_JWT -Value $false -Scope Global
        }
    }
}