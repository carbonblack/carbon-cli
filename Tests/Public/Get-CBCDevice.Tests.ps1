using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Get-CbcDevice" {

	Context "When using multiple connections with a specific server" {

		BeforeAll {
			$s1 = [CbcServer]::new("https://t.te/","test","test")
			$s2 = [CbcServer]::new("https://t.te2/","test2","test2")
			$global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
			$global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
			$global:CBC_CONFIG.currentConnections.Add($s2) | Out-Null
		}

		It "Should return devices only from the specific server" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 200
					Content = Get-Content "$ProjectRoot/Tests/resources/device_api/all_devices.json"
				}
			}

			$devices = Get-CbcDevice -Server @($s1)

			$devices.Count | Should -Be 3
			$devices[0].User | Should -Be "test1@carbonblack.com"
			$devices[0].CBCServer | Should -Be $s1
			$devices[1].User | Should -Be "test2@carbonblack.com"
			$devices[2].User | Should -Be "test3@carbonblack.com"
			$devices[0].id | Should -Be 1
			$devices[1].id | Should -Be 2
			$devices[2].id | Should -Be 3
		}
	}
	Context "When using the 'default' parameter set" {
		Context "When using one connection" {

			BeforeAll {
				$s1 = [CbcServer]::new("https://t.te/","test","test")
				$global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
				$global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
			}

			Context "When not using any params" {
				It "Should return all the devices within the current connection" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/device_api/all_devices.json"
						}
					}

					$devices = Get-CbcDevice
					$devices.Count | Should -Be 3
					$devices[0].User | Should -Be "test1@carbonblack.com"
					$devices[0].CBCServer | Should -Be $s1
					$devices[1].User | Should -Be "test2@carbonblack.com"
					$devices[2].User | Should -Be "test3@carbonblack.com"
					$devices[0].id | Should -Be 1
					$devices[1].id | Should -Be 2
					$devices[2].id | Should -Be 3
				}
			}

			Context "When using the -Exclude parameter" {
				It "Should return the devices according to the exclusion" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
						$Method -eq "POST" -and
						$Server -eq $s1 -and
						(
							($Body | ConvertFrom-Json).rows -eq 50 -and
							($Body | ConvertFrom-Json).exclusions.sensor_version[0] -eq "windows:1.0.0"
						)
					}
					$Exclusions = @{
						"sensor_version" = @("windows:1.0.0")
					}

					$devices = Get-CbcDevice -Exclude $Exclusions

					$devices.Count | Should -Be 1
					$devices[0].CBCServer | Should -Be $s1
					$devices[0].User | Should -Be "test3@carbonblack.com"
					$devices[0].os | Should -Be "LINUX"
				}
			}
			Context "When using the -Include parameter" {
				It "Should return the devices according to the inclusion" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/device_api/criteria_devices.json"
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
						$Method -eq "POST" -and
						($Server -eq $s1 -or $Server -eq $s2) -and
						(
							($Body | ConvertFrom-Json).rows -eq 50 -and
							($Body | ConvertFrom-Json).criteria.os[0] -eq "WINDOWS"
						)
					}
					$Criteria = @{
						"os" = @("WINDOWS")
					}

					$devices = Get-CbcDevice -Include $Criteria

					$devices.Count | Should -Be 2
					$devices[0].CBCServer | Should -Be $s1
					$devices[1].CBCServer | Should -Be $s1
					$devices[0].User | Should -Be "test1@carbonblack.com"
					$devices[1].User | Should -Be "test2@carbonblack.com"
					$devices[0].os | Should -Be "WINDOWS"
					$devices[1].os | Should -Be "WINDOWS"
				}
			}
			Context "When using the -Include -Exclude and -MaxResults params" {
				It "Should return the devices according to the inclusion and exclusion" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_criteria_devices.json"
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
						$Method -eq "POST" -and
						$Server -eq $s1 -and
						(
							($Body | ConvertFrom-Json).rows -eq 20 -and
							($Body | ConvertFrom-Json).criteria.os[0] -eq "WINDOWS" -and
							($Body | ConvertFrom-Json).exclusions.sensor_version[0] -eq "windows:1.0.0"
						)
					}
					$Criteria = @{
						"os" = @("WINDOWS")
					}
					$Exclusions = @{
						"sensor_version" = @("windows:1.0.0")
					}

					$devices = Get-CbcDevice -Exclude $Exclusions -Include $Criteria -MaxResults 20

					$devices.Count | Should -Be 3
					$devices[0].User | Should -Be "test1@carbonblack.com"
					$devices[1].User | Should -Be "test2@carbonblack.com"
					$devices[2].User | Should -Be "test3@carbonblack.com"
					$devices[0].id | Should -Be 1
					$devices[1].id | Should -Be 2
					$devices[2].id | Should -Be 3
				}
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

			Context "When not using any params" {
				It "Should return all the devices from multiple servers" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/device_api/all_devices.json"
						}
					}

					$devices = Get-CbcDevice

					$devices.Count | Should -Be 6
					$devices[0].User | Should -Be "test1@carbonblack.com"
					$devices[2].User | Should -Be "test3@carbonblack.com"
					$devices[0].id | Should -Be 1
					$devices[2].id | Should -Be 3
					$devices[0].CBCServer | Should -Be $s1
					$devices[2].CBCServer | Should -Be $s1
					$devices[3].User | Should -Be "test1@carbonblack.com"
					$devices[5].User | Should -Be "test3@carbonblack.com"
					$devices[3].id | Should -Be 1
					$devices[5].id | Should -Be 3
					$devices[3].CBCServer | Should -Be $s2
					$devices[5].CBCServer | Should -Be $s2
				}
			}
			Context "When using the -Exclude parameter" {
				It "Should return the devices according to the exclusion from multiple servers" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
						$Method -eq "POST" -and
						($Server -eq $s1 -or $Server -eq $s2) -and
						(
							($Body | ConvertFrom-Json).rows -eq 50 -and
							($Body | ConvertFrom-Json).exclusions.sensor_version[0] -eq "windows:1.0.0"
						)
					}
					$Exclusions = @{
						"sensor_version" = @("windows:1.0.0")
					}

					$devices = Get-CbcDevice -Exclude $Exclusions

					$devices.Count | Should -Be 2
					$devices[0].CBCServer | Should -Be $s1
					$devices[0].User | Should -Be "test3@carbonblack.com"
					$devices[0].os | Should -Be "LINUX"
					$devices[1].CBCServer | Should -Be $s2
					$devices[1].User | Should -Be "test3@carbonblack.com"
					$devices[1].os | Should -Be "LINUX"
				}
			}
			Context "When using the -Include parameter" {
				It "Should return the devices according to the inclusion from multiple servers" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/device_api/criteria_devices.json"
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
						$Method -eq "POST" -and
						($Server -eq $s1 -or $Server -eq $s2) -and
						(
							($Body | ConvertFrom-Json).rows -eq 50 -and
							($Body | ConvertFrom-Json).criteria.os[0] -eq "WINDOWS"
						)
					}

					$Criteria = @{
						"os" = @("WINDOWS")
					}

					$devices = Get-CbcDevice -Include $Criteria

					$devices.Count | Should -Be 4
					$devices[0].CBCServer | Should -Be $s1
					$devices[1].CBCServer | Should -Be $s1
					$devices[0].User | Should -Be "test1@carbonblack.com"
					$devices[1].User | Should -Be "test2@carbonblack.com"
					$devices[0].os | Should -Be "WINDOWS"
					$devices[1].os | Should -Be "WINDOWS"

					$devices[2].CBCServer | Should -Be $s2
					$devices[3].CBCServer | Should -Be $s2
					$devices[2].User | Should -Be "test1@carbonblack.com"
					$devices[3].User | Should -Be "test2@carbonblack.com"
					$devices[2].os | Should -Be "WINDOWS"
					$devices[3].os | Should -Be "WINDOWS"
				}
			}
			Context "When using the -Include and -Exclude params" {
				It "Should return the devices according to the inclusion and exclusion from multiple servers" {
					Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
						return @{
							StatusCode = 200
							Content = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_criteria_devices.json"
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
						$Method -eq "POST" -and
						($Server -eq $s1 -or $Server -eq $s2) -and
						(
							($Body | ConvertFrom-Json).rows -eq 50 -and
							($Body | ConvertFrom-Json).criteria.os[0] -eq "WINDOWS" -and
							($Body | ConvertFrom-Json).exclusions.sensor_version[0] -eq "windows:1.0.0"
						)
					}
					$Criteria = @{
						"os" = @("WINDOWS")
					}
					$Exclusions = @{
						"sensor_version" = @("windows:1.0.0")
					}

					$devices = Get-CbcDevice -Exclude $Exclusions -Include $Criteria

					$devices.Count | Should -Be 6
					$devices[0].CBCServer | Should -Be $s1
					$devices[5].CBCServer | Should -Be $s2
					$devices[0].User | Should -Be "test1@carbonblack.com"
					$devices[1].User | Should -Be "test2@carbonblack.com"
					$devices[2].User | Should -Be "test3@carbonblack.com"
					$devices[0].id | Should -Be 1
					$devices[1].id | Should -Be 2
					$devices[2].id | Should -Be 3
					$devices[3].User | Should -Be "test1@carbonblack.com"
					$devices[4].User | Should -Be "test2@carbonblack.com"
					$devices[5].User | Should -Be "test3@carbonblack.com"
					$devices[3].id | Should -Be 1
					$devices[4].id | Should -Be 2
					$devices[5].id | Should -Be 3
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

			It "Should return device with the same id" {
				Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
					return @{
						StatusCode = 200
						Content = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
					}
				}

				$devices = Get-CbcDevice -Id "5765373"

				$devices.Count | Should -Be 1
				$devices[0].id | Should -Be "5765373"
				$devices[0].User | Should -Be "vagrant"
			}

			It "Should return device with the same id without '-Id' param" {
				Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
					return @{
						StatusCode = 200
						Content = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
					}
				}

				$devices = Get-CbcDevice "5765373"

				$devices.Count | Should -Be 1
				$devices[0].id | Should -Be "5765373"
				$devices[0].User | Should -Be "vagrant"
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
						Content = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
					}
				}

				$devices = Get-CbcDevice -Id "5765373"

				$devices.Count | Should -Be 2
				$devices[0].id | Should -Be "5765373"
				$devices[0].User | Should -Be "vagrant"
			}

			It "Should return devices with the same id without '-Id' param from multiple servers" {
				Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
					return @{
						StatusCode = 200
						Content = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
					}
				}

				$devices = Get-CbcDevice "5765373"

				$devices.Count | Should -Be 2
				$devices[0].id | Should -Be "5765373"
				$devices[0].User | Should -Be "vagrant"
			}
		}
	}

}
