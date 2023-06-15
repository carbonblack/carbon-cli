using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Get-CbcAlert" {
	Context "When using the 'default' parameter set" {

		Context "When using one connection" {
			BeforeAll {
				$Uri1 = "https://t.te1/"
				$Org1 = "test1"
				$secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
				$s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
				$global:DefaultCbcServers = [System.Collections.ArrayList]@()
				$global:DefaultCbcServers.Add($s1) | Out-Null
			}

			Context "When raising exception from get alerts" {
				It "Should write an error based on the exception that is returned" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						@{
							StatusCode = 500
							Content    = ""
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Search"] -and
						$Server -eq $s1 -and
						$Method -eq "POST" -and
						($Body | ConvertFrom-Json).rows -eq 50
					}

					{ Get-CbcAlert -ErrorAction Stop } | Should -Throw
				}
			}

			Context "When not using any params" {
				It "Should return all the alerts within the current connection" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						@{
							StatusCode = 200
							Content    = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Search"] -and
						$Server -eq $s1 -and
						$Method -eq "POST" -and
						($Body | ConvertFrom-Json).rows -eq 50
					}

					$alerts = Get-CbcAlert
					$alerts.Count | Should -Be 1
					$alerts[0].Server | Should -Be $s1
				}
			}

			Context "When using the -DeviceId parameter" {
				It "Should return the alerts according to the deviceid" {
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
							($Body | ConvertFrom-Json).criteria.device_id -eq 388948
						)
					}

					$alerts = Get-CbcAlert -DeviceId 388948

					$alerts[0].category | Should -Be "MONITORED"
					$alerts[0].Server | Should -Be $s1
				}
			}

			Context "When using the -Category, -PolicyName, -ThreatId, -Type, -MinSeverity parameter" {
				It "Should return the alerts according to the params" {
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
							($Body | ConvertFrom-Json).criteria.category -eq "MONITORED" -and
							($Body | ConvertFrom-Json).criteria.policy_name -eq "Standard" -and
							($Body | ConvertFrom-Json).criteria.threat_id -eq "xxx" -and
							($Body | ConvertFrom-Json).criteria.type -eq "CB_ANALYTICS" -and
							($Body | ConvertFrom-Json).criteria.minimum_severity -eq 3
						)
					}

					$alerts = Get-CbcAlert -Category "MONITORED" -PolicyName "Standard" -ThreatId "xxx" -Type "CB_ANALYTICS" -MinSeverity 3

					$alerts[0].category | Should -Be "MONITORED"
					$alerts[0].Server | Should -Be $s1
				}
			}

			Context "When using the -Include parameter" {
				It "Should return the alerts according to the inclusion" {
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
							($Body | ConvertFrom-Json).criteria.category -eq "MONITORED"
						)
					}

					$Criteria = @{
						"category" = "MONITORED"
					}
					$alerts = Get-CbcAlert -Include $Criteria

					$alerts[0].category | Should -Be "MONITORED"
					$alerts[0].Server | Should -Be $s1
				}

				It "Should not return alerts, but exception" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						@{
							StatusCode = 500
							Content    = ""
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Search"] -and
						$Method -eq "POST" -and
						$Server -eq $s1 -and
						(
							($Body | ConvertFrom-Json).rows -eq 50 -and
							($Body | ConvertFrom-Json).criteria.category -eq "MONITORED"
						)
					}

					$Criteria = @{
						"category" = "MONITORED"
					}
					{Get-CbcAlert -Include $Criteria -ErrorAction Stop} | Should -Throw
				}
			}

			Context "When using the -Include -MaxResults params" {
				It "Should return the alerts according to the inclusion and max results" {
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
							($Body | ConvertFrom-Json).rows -eq 20 -and
							($Body | ConvertFrom-Json).criteria.category -eq "MONITORED"
						)
					}
					$Criteria = @{
						"category" = "MONITORED"
					}

					$alerts = Get-CbcAlert -Include $Criteria -MaxResults 20
					$alerts[0].category | Should -Be "MONITORED"
					$alerts[0].Server | Should -Be $s1
				}
			}
		}

		Context "When using multiple connections" {
			BeforeAll {
				$Uri1 = "https://t.te1/"
				$Org1 = "test1"
				$secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
				$Uri2 = "https://t.te2/"
				$Org2 = "test2"
				$secureToken2 = "test2" | ConvertTo-SecureString -AsPlainText
				$s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
				$s2 = [CbcServer]::new($Uri2, $Org2, $secureToken2)
				$global:DefaultCbcServers = [System.Collections.ArrayList]@()
				$global:DefaultCbcServers.Add($s1) | Out-Null
				$global:DefaultCbcServers.Add($s2) | Out-Null
			}

			Context "When not using any params" {
				It "Should return all the alerts" {
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
						($Body | ConvertFrom-Json).rows -eq 50
					}

					$alerts = Get-CbcAlert
					$alerts.Count | Should -Be 2
					$alerts[0].type | Should -Be "CB_ANALYTICS"
					$alerts[0].Server | Should -Be $s1
					$alerts[1].type | Should -Be "WATCHLIST"
					$alerts[1].Server | Should -Be $s2
				}
			}

			Context "When using the -Include parameter" {
				It "Should return the alerts according to the inclusion" {
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
							($Body | ConvertFrom-Json).criteria.category -eq "MONITORED"
						)
					}

					$Criteria = @{
						"category" = "MONITORED"
					}
					$alerts = Get-CbcAlert -Include $Criteria

					$alerts.Count | Should -Be 2
					$alerts[0].category | Should -Be "MONITORED"
					$alerts[0].Server | Should -Be $s1
					$alerts[1].category | Should -Be "MONITORED"
					$alerts[1].Server | Should -Be $s2
				}
			}

			Context "When using the -Include -MaxResults params" {
				It "Should return the alerts according to the inclusion and max results" {
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
							($Body | ConvertFrom-Json).rows -eq 20 -and
							($Body | ConvertFrom-Json).criteria.category -eq "MONITORED"
						)
					}

					$Criteria = @{
						"category" = "MONITORED"
					}
					$alerts = Get-CbcAlert -Include $Criteria -MaxResults 20

					$alerts[0].category | Should -Be "MONITORED"
					$alerts[0].Server | Should -Be $s1
					$alerts[1].category | Should -Be "MONITORED"
					$alerts[1].Server | Should -Be $s2
				}
			}

			Context "When not using Server" {
				It "Should return all the alerts for specific Server" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						@{
							StatusCode = 200
							Content    = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Search"] -and
						$Method -eq "POST" -and
						$Server -eq $s1 -and
						($Body | ConvertFrom-Json).rows -eq 50
					}

					$alerts = Get-CbcAlert -Server $s1
					$alerts.Count | Should -Be 1
					$alerts[0].type | Should -Be "CB_ANALYTICS"
					$alerts[0].Server | Should -Be $s1
				}
			}
		}
	}

	Context "When using the 'id' parameter set" {
		Context "When using one connection" {
			BeforeAll {
				$Uri1 = "https://t.te1/"
				$Org1 = "test1"
				$secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
				$s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
				$global:DefaultCbcServers = [System.Collections.ArrayList]@()
				$global:DefaultCbcServers.Add($s1) | Out-Null
			}

			It "Should return alerts with the same id" {
				Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
					}
				} -ParameterFilter {
					$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Search"] -and
					$Method -eq "POST" -and
					$Server -eq $s1
					($Body | ConvertFrom-Json).criteria.id -eq 1
				}

				$alerts = Get-CbcAlert -Id "1"

				$alerts.Count | Should -Be 1
				$alerts[0].Id | Should -Be "1"
				$alerts[0].Server | Should -Be $s1
			}

			It "Should not return alerts but exception" {
				Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
					@{
						StatusCode = 500
						Content    = ""
					}
				} -ParameterFilter {
					$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Search"] -and
					$Method -eq "POST" -and
					$Server -eq $s1
					($Body | ConvertFrom-Json).criteria.id -eq 1
				}

				{Get-CbcAlert -Id "1" -ErrorAction Stop} | Should -Throw
			}

			It "Should return alerts with the same id without '-Id' param" {
				Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
					}
				} -ParameterFilter {
					$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Search"] -and
					$Method -eq "POST" -and
					$Server -eq $s1
					($Body | ConvertFrom-Json).criteria.id -eq 1
				}

				$alerts = Get-CbcAlert "1"

				$alerts.Count | Should -Be 1
				$alerts[0].Id | Should -Be "1"
				$alerts[0].Server | Should -Be $s1
			}
		}

		Context "When using multiple connection" {
			BeforeAll {
				$Uri1 = "https://t.te1/"
				$Org1 = "test1"
				$secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
				$Uri2 = "https://t.te2/"
				$Org2 = "test2"
				$secureToken2 = "test2" | ConvertTo-SecureString -AsPlainText
				$s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
				$s2 = [CbcServer]::new($Uri2, $Org2, $secureToken2)
				$global:DefaultCbcServers = [System.Collections.ArrayList]@()
				$global:DefaultCbcServers.Add($s1) | Out-Null
				$global:DefaultCbcServers.Add($s2) | Out-Null
			}

			It "Should return alerts with the same id from multiple servers" {
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
					($Server -eq $s1 -or $Server -eq $s2)
				}

				$alerts = Get-CbcAlert -Id "1"

				$alerts.Count | Should -Be 2
				$alerts[0].Id | Should -Be "1"
				$alerts[0].Type | Should -Be "CB_ANALYTICS"
				$alerts[0].Server | Should -Be $s1
				$alerts[1].Id | Should -Be "1"
				$alerts[1].Type | Should -Be "WATCHLIST"
				$alerts[1].Server | Should -Be $s2
			}

			It "Should return alert from one server when connected to multiple servers" {
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
							Content    = Get-Content "$ProjectRoot/Tests/resources/alerts_api/no_alerts.json"
						}
					}
				} -ParameterFilter {
					$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Search"] -and
					$Method -eq "POST" -and
					($Server -eq $s1 -or $Server -eq $s2)
				}

				$alerts = Get-CbcAlert -Id 1

				$alerts.Count | Should -Be 1
				$alerts[0].Id | Should -Be "1"
				$alerts[0].Server | Should -Be $s1
			}

			It "Should return alerts with the same id without '-Id' param from multiple servers" {
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
					($Server -eq $s1 -or $Server -eq $s2)

				}

				$alerts = Get-CbcAlert "1"

				$alerts.Count | Should -Be 2
				$alerts[0].Id | Should -Be "1"
				$alerts[0].Type | Should -Be "CB_ANALYTICS"
				$alerts[0].Server | Should -Be $s1
				$alerts[1].Id | Should -Be "1"
				$alerts[1].Type | Should -Be "WATCHLIST"
				$alerts[1].Server | Should -Be $s2
			}
		}
	}
}
