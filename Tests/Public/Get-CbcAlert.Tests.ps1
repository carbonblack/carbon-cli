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
				$s1 = [CbcServer]::new("https://t.te/","test","test")
				$global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
				$global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
			}

            Context "When not using any params" {
				It "Should return all the alerts within the current connection" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
						}
					}

					$alerts = Get-CbcAlert
					$alerts.Count | Should -Be 1
                    $alerts[0].Server | Should -Be $s1
				}
			}

            Context "When using the -Include parameter" {
				It "Should return the alerts according to the inclusion" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
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
			}

            Context "When using the -Include -MaxResults params" {
				It "Should return the alerts according to the inclusion and max results" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
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
				$s1 = [CbcServer]::new("https://t.te/","test","test")
				$s2 = [CbcServer]::new("https://t.te2/","test2","test2")
				$global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
				$global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
				$global:CBC_CONFIG.currentConnections.Add($s2) | Out-Null
			}

            Context "When not using any params" {
				It "Should return all the alerts" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
						}
					}

					$alerts = Get-CbcAlert
					$alerts.Count | Should -Be 2
                    $alerts[0].Server | Should -Be $s1
                    $alerts[1].Server | Should -Be $s2
				}
			}

            Context "When using the -Include parameter" {
				It "Should return the alerts according to the inclusion" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
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
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
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
        }
    }
    Context "When using the 'id' parameter set" {
        Context "When using one connection" {

			BeforeAll {
				$s1 = [CbcServer]::new("https://t.te/","test","test")
				$global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
				$global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
			}

			It "Should return alerts with the same id" {
				Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    return @{
                        StatusCode = 200
                        Content = Get-Content "$ProjectRoot/Tests/resources/alerts_api/specific_alert.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["SpecificAlert"]
                }

				$alerts = Get-CbcAlert -Id "1"

				$alerts.Count | Should -Be 1
				$alerts[0].Id | Should -Be "1"
				$alerts[0].Category | Should -Be "THREAT"
			}

			It "Should return device with the same id without '-Id' param" {
				Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
					return @{
						StatusCode = 200
						Content = Get-Content "$ProjectRoot/Tests/resources/alerts_api/specific_alert.json"
					}
				}

				$alerts = Get-CbcAlert "1"

				$alerts.Count | Should -Be 1
				$alerts[0].Id | Should -Be "1"
				$alerts[0].Category | Should -Be "THREAT"
			}
		}
		Context "When using multiple connection" {

			BeforeAll {
				$s1 = [CbcServer]::new("https://t.te/","test","test")
				$s2 = [CbcServer]::new("https://t.te2/","test2","test2")
				$global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
				$global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
				$global:CBC_CONFIG.currentConnections.Add($s2) | Out-Null
			}

			It "Should return devices with the same id from multiple servers" {

				Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
					return @{
						StatusCode = 200
						Content = Get-Content "$ProjectRoot/Tests/resources/alerts_api/specific_alert.json"
					}
				}

				$alerts = Get-CbcAlert -Id "1"

				$alerts.Count | Should -Be 2
				$alerts[0].Id | Should -Be "1"
				$alerts[1].Id | Should -Be "1"
				$alerts[0].Category | Should -Be "THREAT"
				$alerts[1].Category | Should -Be "THREAT"
			}

			It "Should return devices with the same id without '-Id' param from multiple servers" {
				Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
					return @{
						StatusCode = 200
						Content = Get-Content "$ProjectRoot/Tests/resources/alerts_api/specific_alert.json"
					}
				}

				$alerts = Get-CbcAlert "5765373"

				$alerts.Count | Should -Be 2
				$alerts[0].Id | Should -Be "1"
				$alerts[0].Category | Should -Be "THREAT"
			}
		}
    }
}
