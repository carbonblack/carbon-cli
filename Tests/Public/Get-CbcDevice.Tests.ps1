using module ..\..\src\CarbonCLI.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name CarbonCLI -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\CarbonCLI.psm1 -Force
}

AfterAll {
	Remove-Module -Name CarbonCLI -Force
}

Describe "Get-CbcDevice" {
	Context "When using multiple connections with a specific server" {
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

		It "Should return devices only from the specific server" {
			Mock Invoke-CbcRequest -ModuleName CarbonCLI {
				@{
					StatusCode = 200
					Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/all_devices.json"
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
				$Server -eq $s1 -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).rows -eq 50
			}

			$devices = Get-CbcDevice -Server @($s1)

			$devices.Count | Should -Be 3
			$devices[0].Server | Should -Be $s1
			$devices[0].id | Should -Be 1
			$devices[1].id | Should -Be 2
			$devices[1].Server | Should -Be $s1
			$devices[2].id | Should -Be 3
			$devices[2].Server | Should -Be $s1
		}
	}

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

			Context "When not using any params" {
				It "Should return all the devices within the current connection" {
					Mock Invoke-CbcRequest -ModuleName CarbonCLI {
						@{
							StatusCode = 200
							Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/all_devices.json"
						}
					} -ParameterFilter {
						$Server -eq $s1 -and
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
						$Method -eq "POST" -and
						($Body | ConvertFrom-Json).rows -eq 50
					}

					$devices = Get-CbcDevice

					$devices.Count | Should -Be 3
					$devices[0].Server | Should -Be $s1
					$devices[0].id | Should -Be 1
					$devices[1].Server | Should -Be $s1
					$devices[1].id | Should -Be 2
					$devices[2].Server | Should -Be $s1
					$devices[2].id | Should -Be 3
				}
			}

			Context "When returning error from the API" {
				It "Should not return any devices but an error" {
					Mock Invoke-CbcRequest -ModuleName CarbonCLI {
						@{
							StatusCode = 500
							Content    = ""
						}
					} -ParameterFilter {
						$Server -eq $s1 -and
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
						$Method -eq "POST" -and
						($Body | ConvertFrom-Json).rows -eq 50
					}

					{Get-CbcDevice -ErrorAction Stop} | Should -Throw
				}
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

			Context "When not using any params" {
				It "Should return all the devices from multiple servers" {
					Mock Invoke-CbcRequest -ModuleName CarbonCLI {
						if ($Server -eq $s1) {
							@{
								StatusCode = 200
								Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/all_devices.json"
							}
						}
						else {
							@{
								StatusCode = 200
								Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
							}
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
						$Method -eq "POST" -and
						($Body | ConvertFrom-Json).rows -eq 50
					}

					$devices = Get-CbcDevice

					$devices.Count | Should -Be 4
					$devices[0].id | Should -Be 1
					$devices[0].Server | Should -Be $s1
					$devices[1].id | Should -Be 2
					$devices[1].Server | Should -Be $s1
					$devices[2].id | Should -Be 3
					$devices[2].Server | Should -Be $s1			
					$devices[3].id | Should -Be 5765373
					$devices[3].Server | Should -Be $s2
				}
			}
		}
	}

	Context "When using the 'IncludeExclude' parameter set" {
		Context "When using one connection" {
			BeforeAll {
				$Uri1 = "https://t.te1/"
				$Org1 = "test1"
				$secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
			$s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
				$global:DefaultCbcServers = [System.Collections.ArrayList]@()
				$global:DefaultCbcServers.Add($s1) | Out-Null
			}

			Context "When using the -Exclude parameter" {
				It "Should return the devices according to the exclusion" {
					Mock Invoke-CbcRequest -ModuleName CarbonCLI {
						@{
							StatusCode = 200
							Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
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
					$devices[0].Server | Should -Be $s1
					$devices[0].os | Should -Be "WINDOWS"
				}
			}

			Context "When using the -Exclude parameter - exception" {
				It "Should return the devices according to the exclusion - exception" {
					Mock Invoke-CbcRequest -ModuleName CarbonCLI {
						@{
							StatusCode = 500
							Content    = ""
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
					{Get-CbcDevice -Exclude $Exclusions -ErrorAction Stop} | Should -Throw
				}
			}

			Context "When using the -Include parameter" {
				It "Should return the devices according to the inclusion" {
					Mock Invoke-CbcRequest -ModuleName CarbonCLI {
						@{
							StatusCode = 200
							Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/criteria_devices.json"
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
						$Method -eq "POST" -and
						($Server -eq $s1) -and
						(
							($Body | ConvertFrom-Json).rows -eq 50 -and
							($Body | ConvertFrom-Json).criteria.os[0] -eq "WINDOWS" -and
							($Body | ConvertFrom-Json).criteria.os.Count -eq 1 -and
							($Body | ConvertFrom-Json).criteria.Count -eq 1
						)
					}

					$Criteria = @{
						"os" = @("WINDOWS")
					}
					$devices = Get-CbcDevice -Include $Criteria

					$devices.Count | Should -Be 2
					$devices[0].Server | Should -Be $s1
					$devices[0].User | Should -Be "test1@carbonblack.com"
					$devices[0].os | Should -Be "WINDOWS"
					
					$devices[1].User | Should -Be "test2@carbonblack.com"
					$devices[1].Server | Should -Be $s1
					$devices[1].os | Should -Be "WINDOWS"
				}
			}

			Context "When using the -Include -Exclude and -MaxResults params" {
				It "Should return the devices according to the inclusion and exclusion" {
					Mock Invoke-CbcRequest -ModuleName CarbonCLI {
						@{
							StatusCode = 200
							Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_criteria_devices.json"
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
					$devices[0].id | Should -Be 1
					$devices[0].Server | Should -Be $s1
					$devices[1].id | Should -Be 2
					$devices[1].Server | Should -Be $s1
					$devices[2].id | Should -Be 3
					$devices[2].Server | Should -Be $s1
				}
			}

			Context "When using the Os, OsVersion, Status, Priority params" {
				It "Should return the devices according to the provided filters" {
					Mock Invoke-CbcRequest -ModuleName CarbonCLI {
						@{
							StatusCode = 200
							Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
						$Method -eq "POST" -and
						$Server -eq $s1 -and
						(
							($Body | ConvertFrom-Json).rows -eq 50 -and
							($Body | ConvertFrom-Json).criteria.os[0] -eq "WINDOWS" -and
							($Body | ConvertFrom-Json).criteria.os_version[0] -eq "Windows 10 x64" -and
							($Body | ConvertFrom-Json).criteria.status[0] -eq "REGISTERED" -and
							($Body | ConvertFrom-Json).criteria.target_priority[0] -eq "MEDIUM"
						)
					}

					$devices = Get-CbcDevice -Os "WINDOWS" -OsVersion "Windows 10 x64" -Status "REGISTERED" -TargetPriority "MEDIUM"

					$devices.Count | Should -Be 1
					$devices[0].id | Should -Be 5765373
					$devices[0].Server | Should -Be $s1
				}
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

			Context "When using the -Exclude parameter" {
				It "Should return the devices according to the exclusion from multiple servers" {
					Mock Invoke-CbcRequest -ModuleName CarbonCLI {
						if ($Server -eq $s1) {
							@{
								StatusCode = 200
								Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
							}
						}
						else {
							@{
								StatusCode = 200
								Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
							}
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
					$devices[0].Server | Should -Be $s1
					$devices[0].User | Should -Be "test3@carbonblack.com"
					$devices[0].os | Should -Be "WINDOWS"
					$devices[1].Server | Should -Be $s2
					$devices[1].User | Should -Be "vagrant"
					$devices[1].os | Should -Be "WINDOWS"
				}
			}

			Context "When using the -Include parameter" {
				It "Should return the devices according to the inclusion from multiple servers" {
					Mock Invoke-CbcRequest -ModuleName CarbonCLI {
						if ($Server -eq $s1) {
							@{
								StatusCode = 200
								Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/criteria_devices.json"
							}
						}
						else {
							@{
								StatusCode = 200
								Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
							}
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

					$devices.Count | Should -Be 3
					$devices[0].Server | Should -Be $s1
					$devices[0].User | Should -Be "test1@carbonblack.com"
					$devices[0].os | Should -Be "WINDOWS"
					$devices[1].Server | Should -Be $s1
					$devices[1].User | Should -Be "test2@carbonblack.com"
					$devices[1].os | Should -Be "WINDOWS"
					$devices[2].Server | Should -Be $s2
					$devices[2].User | Should -Be "vagrant"
					$devices[2].os | Should -Be "WINDOWS"
				}
			}

			Context "When using the -Include and -Exclude params" {
				It "Should return the devices according to the inclusion and exclusion from multiple servers" {
					Mock Invoke-CbcRequest -ModuleName CarbonCLI {
						if ($Server -eq $s1) {
							@{
								StatusCode = 200
								Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_criteria_devices.json"
							}
						}
						else {
							@{
								StatusCode = 200
								Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
							}
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

					$devices.Count | Should -Be 4
					$devices[0].Server | Should -Be $s1
					$devices[0].id | Should -Be 1
					$devices[1].Server | Should -Be $s1
					$devices[1].id | Should -Be 2
					$devices[2].Server | Should -Be $s1
					$devices[2].id | Should -Be 3
					$devices[3].Server | Should -Be $s2
					$devices[3].id | Should -Be 5765373
				}
			}

			Context "When using the Os, OsVersion, Status, Priority params with multiple connections" {
				It "Should return the devices according to the provided filters" {
					Mock Invoke-CbcRequest -ModuleName CarbonCLI {
						@{
							StatusCode = 200
							Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
						}
					} -ParameterFilter {
						$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
						$Method -eq "POST" -and
						($Server -eq $s1 -or $Server -eq $s2) -and
						(
							($Body | ConvertFrom-Json).rows -eq 50 -and
							($Body | ConvertFrom-Json).criteria.os[0] -eq "WINDOWS" -and
							($Body | ConvertFrom-Json).criteria.os_version[0] -eq "Windows 10 x64" -and
							($Body | ConvertFrom-Json).criteria.status[0] -eq "REGISTERED" -and
							($Body | ConvertFrom-Json).criteria.target_priority[0] -eq "MEDIUM"
						)
					}

					$devices = Get-CbcDevice -Os "WINDOWS" -OsVersion "Windows 10 x64" -Status "REGISTERED" -TargetPriority "MEDIUM"

					$devices.Count | Should -Be 2
					$devices[0].id | Should -Be 5765373
					$devices[0].Server | Should -Be $s1
					$devices[1].id | Should -Be 5765373
					$devices[1].Server | Should -Be $s2
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

			It "Should return device with the same id" {
				Mock Invoke-CbcRequest -ModuleName CarbonCLI {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
					}
				} -ParameterFilter {
					$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
					$Method -eq "POST" -and
					$Server -eq $s1 -and
					(
						($Body | ConvertFrom-Json).rows -eq 50 -and
						($Body | ConvertFrom-Json).criteria.id[0] -eq "5765373"
					)
				}

				$devices = Get-CbcDevice -Id "5765373"

				$devices.Count | Should -Be 1
				$devices[0].id | Should -Be "5765373"
				$devices[0].Server | Should -Be $s1
			}

			It "Should return device with the same id without '-Id' param" {
				Mock Invoke-CbcRequest -ModuleName CarbonCLI {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
					}
				} -ParameterFilter {
					$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
					$Method -eq "POST" -and
					$Server -eq $s1 -and
					(
						($Body | ConvertFrom-Json).rows -eq 50 -and
						($Body | ConvertFrom-Json).criteria.id[0] -eq "5765373"
					)
				}

				$devices = Get-CbcDevice "5765373"

				$devices.Count | Should -Be 1
				$devices[0].Server | Should -Be $s1
				$devices[0].id | Should -Be "5765373"
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

			It "Should return devices with the same id from multiple servers" {
				Mock Invoke-CbcRequest -ModuleName CarbonCLI {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
					}
					
				} -ParameterFilter {
					$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
					$Method -eq "POST" -and
					(
						($Body | ConvertFrom-Json).rows -eq 50 -and
						($Body | ConvertFrom-Json).criteria.id[0] -eq "5765373"
					)
				}

				$devices = Get-CbcDevice -Id "5765373"

				$devices.Count | Should -Be 2
				$server1Devices = $devices | Where-Object {$_.Server.Uri -eq $Uri1}
				$server1Devices.Count | Should -Be 1
				$server2Devices = $devices | Where-Object {$_.Server.Uri -eq $Uri2}
				$server2Devices.Count | Should -Be 1
				$filteredDevices = $devices | Where-Object {$_.Id -eq "5765373" }
				$filteredDevices.Count | Should -Be 2
			}

			It "Should return devices with the same id without '-Id' param from multiple servers" {
				Mock Invoke-CbcRequest -ModuleName CarbonCLI {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
					}
					
				} -ParameterFilter {
					$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
					$Method -eq "POST" -and
					(
						($Body | ConvertFrom-Json).rows -eq 50 -and
						($Body | ConvertFrom-Json).criteria.id[0] -eq "5765373"
					)
				}

				$devices = Get-CbcDevice "5765373"

				$devices.Count | Should -Be 2
				$server1Devices = $devices | Where-Object {$_.Server.Uri -eq $Uri1}
				$server1Devices.Count | Should -Be 1
				$server2Devices = $devices | Where-Object {$_.Server.Uri -eq $Uri2}
				$server2Devices.Count | Should -Be 1
				$filteredDevices = $devices | Where-Object {$_.Id -eq "5765373" }
				$filteredDevices.Count | Should -Be 2
			}
		}
	}
}