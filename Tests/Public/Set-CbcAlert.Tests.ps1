using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Set-CbcAlert" {
    BeforeAll {
		$s1 = [CbcServer]::new("https://t.te/","test","test")
		$s2 = [CbcServer]::new("https://t.te2/","test2","test2")
		$global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
		$global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
		$global:CBC_CONFIG.currentConnections.Add($s2) | Out-Null

		$alert1 = [CbcAlert]::new(
			"1",
			"123",
			"THREAT",
			"2023-02-01T14:30:02.131Z",
			"2023-02-01T14:27:10.384Z",
			"2023-02-01T14:27:10.384Z",
			"2023-02-01T14:27:10.384Z",
			$null,
			"10574070",
			"milen-test",
			5,
			$null,
			"HIGH",
			"a47a02f7d7b3dfc2c5a6f1606fc5f2bc",
			"CB_ANALYTICS",
			$null,
			$s1
		)
		$alert2 = [CbcAlert]::new(
			"1",
			"123",
			"THREAT",
			"2023-02-01T14:30:02.131Z",
			"2023-02-01T14:27:10.384Z",
			"2023-02-01T14:27:10.384Z",
			"2023-02-01T14:27:10.384Z",
			$null,
			"10574070",
			"milen-test",
			5,
			$null,
			"HIGH",
			"a47a02f7d7b3dfc2c5a6f1606fc5f2bc",
			"CB_ANALYTICS",
			$null,
			$s2
		)
	}
	
	Context "When using a `CbcAlert` object" {
		It "Should dismiss alert" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 200
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Dismiss"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq 1
			}
			$a = Set-CbcAlert -Alert $alert1 -Dismiss $true
			$a | Should -Be ($alert1, $alert1)
		}
	}
	Context "When using `Id` " {
		It "Should dismiss alert by Id" {
			Mock Get-CbcAlert -ModuleName PSCarbonBlackCloud {
				return $alert1
			} -ParameterFilter {
				$Id -eq 1
			}
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 200
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Dismiss"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq 1
			}
			$a = Set-CbcAlert -Id $alert1.Id -Dismiss $true
			$a | Should -Be ($alert1, $alert1)
		}
	}
	Context "When using `Include` " {
		It "Should dismiss alert by proving criteria" {
			Mock Get-CbcAlert -ModuleName PSCarbonBlackCloud {
				return $alert1
			} -ParameterFilter {
				$Include.id[0] -eq $alert1.Id
			}
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 200
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Dismiss"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq 1
			}
			$a = Set-CbcAlert -Include @{"id" = @($alert1.Id)} -Dismiss $true
			$a | Should -Be ($alert1, $alert1)
		}
	}
}
