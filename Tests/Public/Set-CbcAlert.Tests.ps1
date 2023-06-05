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
		$s1 = [CbcServer]::new("https://t.te/", "test", "test")
		$s2 = [CbcServer]::new("https://t.te2/", "test2", "test2")
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
	}
	
	Context "When using a `CbcAlert` object" {
		It "Should dismiss alert" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
					}
				}
				else {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts_2.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Search"] -and
				$Method -eq "POST" -and
				($Server -eq $s1 -or $Server -eq $s2) -and
				(
					($Body | ConvertFrom-Json).rows -eq 50 -and
					($Body | ConvertFrom-Json).criteria.id[0] -eq "1"
				)
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 200
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Dismiss"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq 1
			}

			$a = Set-CbcAlert -Alert $alert1 -Dismiss $true
			$a.Count | Should -Be 2
			$a[0].Server | Should -Be $s1
			$a[0].Type | Should -Be "CB_ANALYTICS"
			$a[1].Server | Should -Be $s2
			$a[1].Type | Should -Be "WATCHLIST"
		}
	}

	Context "When using `Id` " {
		It "Should dismiss alert by Id" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
					}
				}
				else {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts_2.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Search"] -and
				$Method -eq "POST" -and
				($Server -eq $s1 -or $Server -eq $s2) -and
				(
					($Body | ConvertFrom-Json).rows -eq 50 -and
					($Body | ConvertFrom-Json).criteria.id[0] -eq "1"
				)
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 200
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Dismiss"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq 1
			}
			$a = Set-CbcAlert -Id $alert1.Id -Dismiss $true
			$a.Count | Should -Be 2
			$a[0].Server | Should -Be $s1
			$a[0].Type | Should -Be "CB_ANALYTICS"
			$a[1].Server | Should -Be $s2
			$a[1].Type | Should -Be "WATCHLIST"
		}

		It "Should dismiss alert by Id for specific server" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 200
					Content    = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Search"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).rows -eq 50 -and
					($Body | ConvertFrom-Json).criteria.id[0] -eq "1"
				)
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 200
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Dismiss"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq 1
			}
			$a = Set-CbcAlert -Id $alert1.Id -Server $s1 -Dismiss $true
			$a.Count | Should -Be 1 
			$a[0].Server | Should -Be $s1
			$a[0].Type | Should -Be "CB_ANALYTICS"
		}

		It "Should dismiss alert by Id for specific server error" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 200
					Content    = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Search"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).rows -eq 50 -and
					($Body | ConvertFrom-Json).criteria.id[0] -eq "1"
				)
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 500
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Dismiss"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq 1
			}
			Set-CbcAlert -Id $alert1.Id -Server $s1 -Dismiss $true -ErrorVariable err
			$err | Should -Be "Cannot complete action dismiss alert for alerts  for [test] https://t.te/"
		}
	}
}
