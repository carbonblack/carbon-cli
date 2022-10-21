if ( -not (Get-Module -ListAvailable -Name "PSCarbonBlackCloud")) {
    Import-Module ./src/PSCarbonBlackCloud.psm1
} else {
    # Reload the Module
    Remove-Module ./src/PSCarbonBlackCloud.psm1
    Import-Module ./src/PSCarbonBlackCloud.psm1
}

Invoke-Pester ./Tests