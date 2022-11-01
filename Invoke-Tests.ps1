Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue'
Import-Module ./src/PSCarbonBlackCloud.psm1

Invoke-Pester ./Tests -Output Detailed