using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Get-CbcPolicy" {
    Context "When using the 'default' parameter set" {
        Context "When using one connection" {
            BeforeAll {
                $s1 = [CbcServer]::new("https://t.te/","test","test")
                $global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
                $global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
            }

            It "Should return all policies" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    return @{
                        StatusCode = 200
                        Content = Get-Content "$ProjectRoot/Tests/resources/policies_api/all_policies.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Policies"]["Search"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $Policy = Get-CbcPolicy

                $Policy.Count | Should -Be 1
                $Policy.Name | Should -Be "Standard"
            }
        }
        Context "When using multiple connections" {

            BeforeAll {
				$s1 = [CbcServer]::new("https://t.te/","test","test")
				$s2 = [CbcServer]::new("https://t.te2/","test2","test2")
				$global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
				$global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
				$global:CBC_CONFIG.currentConnections.Add($s2) | Out-Null
			}

            It "Should return all policies" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    return @{
                        StatusCode = 200
                        Content = Get-Content "$ProjectRoot/Tests/resources/policies_api/all_policies.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Policies"]["Search"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                $Policy = Get-CbcPolicy

                $Policy.Count | Should -Be 2
                $Policy[0].Name | Should -Be "Standard"
                $Policy[1].Name | Should -Be "Standard"
            }

        }
    }
}
