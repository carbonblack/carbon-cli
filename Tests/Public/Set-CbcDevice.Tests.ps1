using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Set-CbcDevice" {
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

		$device1 = [CbcDevice]::new(
			"3",
			"REGISTERED",
			"",
			"MEDIUM",
			"Administrator",
			"Test",
			"WINDOWS",
			"01/12/2023 21:54:29",
			"SUSE",
			$s1,
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			$true,
			$true,
			$true,
			"test",
			"test",
			"1",
			"test",
			"test",
			"test",
			"test",
			"test",
			15,
			"test",
			"test",
			"test",
			"test",
			"test"
		)
		$device2 = [CbcDevice]::new(
			"5765373",
			"REGISTERED",
			"",
			"MEDIUM",
			"Administrator",
			"Test",
			"RHEL",
			"01/12/2023 21:54:29",
			"RHEL",
			$s2,
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			"test",
			1,
			"test",
			"test",
			$true,
			$true,
			$true,
			"test",
			"test",
			"1",
			"test",
			"test",
			"test",
			"test",
			"test",
			15,
			"test",
			"test",
			"test",
			"test",
			"test"
		)
	}

	Context "When using a `CbcDevice` object" {
		It "Should quarantine the device - error" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 500
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 3 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "QUARANTINE"
				)
			}
			Set-CbcDevice -Device $device1 -QuarantineEnabled $true  -ErrorVariable err
			$err | Should -BeLike "Cannot complete action QUARANTINE for devices 3 *"
		}

		It "Should quarantine the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 3 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "QUARANTINE"
				)
			}
			$d = Set-CbcDevice -Device $device1 -QuarantineEnabled $true
			$d.Count | Should -Be 1
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be "3"
		}

		It "Should quarantine the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
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
				(
					(($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id -and $Server -eq $s1) -or
				    (($Body | ConvertFrom-Json).criteria.id[0] -eq $device2.Id -and $Server -eq $s2)
				)
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				(
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "QUARANTINE" -and
					(
						(($Body | ConvertFrom-Json).device_id[0] -eq 3 -and $Server -eq $s1) -or
						(($Body | ConvertFrom-Json).device_id[0] -eq 5765373 -and $Server -eq $s2)
					)
				)
			}

			$d = Set-CbcDevice -Device @($device1, $device2) -QuarantineEnabled $true
			$d.Count | Should -Be 2
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
			$d[1].Server | Should -Be $s2
			$d[1].Id | Should -Be 5765373
		}

		It "Should unquarantine the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 3 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "QUARANTINE"
				)
			}

			$d = Set-CbcDevice -Device $device1 -QuarantineEnabled $false
			$d.Count | Should -Be 1
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be "3"
		}

		It "Should unquarantine the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
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
				(
					(($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id -and $Server -eq $s1) -or
				    (($Body | ConvertFrom-Json).criteria.id[0] -eq $device2.Id -and $Server -eq $s2)
				)
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				(
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "QUARANTINE" -and
					(
						(($Body | ConvertFrom-Json).device_id[0] -eq 3 -and $Server -eq $s1) -or
						(($Body | ConvertFrom-Json).device_id[0] -eq 5765373 -and $Server -eq $s2)
					)
				)
			}

			$d = Set-CbcDevice -Device @($device1, $device2) -QuarantineEnabled $false
			$d.Count | Should -Be 2
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
			$d[1].Server | Should -Be $s2
			$d[1].Id | Should -Be 5765373
		}

		It "Should scan the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 3 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "BACKGROUND_SCAN"
				)
			}

			$d = Set-CbcDevice -Device $device1 -ScanEnabled $true
			$d.Count | Should -Be 1
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be "3"
		}

		It "Should scan the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
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
				(
					(($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id -and $Server -eq $s1) -or
				    (($Body | ConvertFrom-Json).criteria.id[0] -eq $device2.Id -and $Server -eq $s2)
				)
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				(
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "BACKGROUND_SCAN" -and
					(
						(($Body | ConvertFrom-Json).device_id[0] -eq 3 -and $Server -eq $s1) -or
						(($Body | ConvertFrom-Json).device_id[0] -eq 5765373 -and $Server -eq $s2)
					)
				)
			}

			$d = Set-CbcDevice -Device @($device1, $device2) -ScanEnabled $true
			$d.Count | Should -Be 2
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
			$d[1].Server | Should -Be $s2
			$d[1].Id | Should -Be 5765373
		}

		It "Should pause the scan on the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 3 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "BACKGROUND_SCAN"
				)
			}
			$d = Set-CbcDevice -Device $device1 -ScanEnabled $false
			$d.Count | Should -Be 1
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be "3"
		}

		It "Should pause the scan on the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
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
				(
					(($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id -and $Server -eq $s1) -or
				    (($Body | ConvertFrom-Json).criteria.id[0] -eq $device2.Id -and $Server -eq $s2)
				)
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				(
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "BACKGROUND_SCAN" -and
					(
						(($Body | ConvertFrom-Json).device_id[0] -eq 3 -and $Server -eq $s1) -or
						(($Body | ConvertFrom-Json).device_id[0] -eq 5765373 -and $Server -eq $s2)
					)
				)
			}

			$d = Set-CbcDevice -Device @($device1, $device2) -ScanEnabled $false
			$d.Count | Should -Be 2
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
			$d[1].Server | Should -Be $s2
			$d[1].Id | Should -Be 5765373
		}

		It "Should update the sensor of the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 3 -and
					($Body | ConvertFrom-Json).options.sensor_version.SUSE -eq "2.4.0.3" -and
					($Body | ConvertFrom-Json).action_type -eq "UPDATE_SENSOR_VERSION"
				)
			}
			$d = Set-CbcDevice -Device $device1 -SensorVersion "2.4.0.3"
			$d.Count | Should -Be 1
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
		}

		It "Should update the sensor of the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
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
				(
					(($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id -and $Server -eq $s1) -or
				    (($Body | ConvertFrom-Json).criteria.id[0] -eq $device2.Id -and $Server -eq $s2)
				)
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				(
					$Server -eq $s1 -and
					($Body | ConvertFrom-Json).device_id -eq 3 -and
					($Body | ConvertFrom-Json).options.sensor_version.SUSE -eq "2.4.0.3" -and
					($Body | ConvertFrom-Json).action_type -eq "UPDATE_SENSOR_VERSION"
				) -or
				(
					$Server -eq $s2 -and
					($Body | ConvertFrom-Json).device_id -eq 5765373 -and
					($Body | ConvertFrom-Json).options.sensor_version.RHEL -eq "2.4.0.3" -and
					($Body | ConvertFrom-Json).action_type -eq "UPDATE_SENSOR_VERSION"
				)
			}

			$d = Set-CbcDevice -Device @($device1, $device2) -SensorVersion "2.4.0.3"
			$d.Count | Should -Be 2
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
			$d[1].Server | Should -Be $s2
			$d[1].Id | Should -Be 5765373
		}

		It "Should uninstall the sensor of the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				(
					$Server -eq $s1 -and
					($Body | ConvertFrom-Json).device_id -eq 3 -and
					($Body | ConvertFrom-Json).action_type -eq "UNINSTALL_SENSOR"
				)
			}
			$d = Set-CbcDevice -Device $device1 -UninstallSensor
			$d.Count | Should -Be 1
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
		}

		It "Should uninstall the sensor of the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
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
				(
					(($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id -and $Server -eq $s1) -or
				    (($Body | ConvertFrom-Json).criteria.id[0] -eq $device2.Id -and $Server -eq $s2)
				)
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				(
					$Server -eq $s1 -and
					($Body | ConvertFrom-Json).device_id -eq 3 -and
					($Body | ConvertFrom-Json).action_type -eq "UNINSTALL_SENSOR"
				) -or
				(
					$Server -eq $s2 -and
					($Body | ConvertFrom-Json).device_id -eq 5765373 -and
					($Body | ConvertFrom-Json).action_type -eq "UNINSTALL_SENSOR"
				)
			}
			$d = Set-CbcDevice -Device @($device1, $device2) -UninstallSensor
			$d.Count | Should -Be 2
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
			$d[1].Server | Should -Be $s2
			$d[1].Id | Should -Be 5765373
		}

		It "Should enable bypass the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 3 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "BYPASS"
				)
			}
			$d = Set-CbcDevice -Device $device1 -BypassEnabled $true
			$d.Count | Should -Be 1
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
		}

		It "Should enable bypass the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
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
				(
					(($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id -and $Server -eq $s1) -or
				    (($Body | ConvertFrom-Json).criteria.id[0] -eq $device2.Id -and $Server -eq $s2)
				)
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				(
					$Server -eq $s1 -and
					($Body | ConvertFrom-Json).device_id -eq 3 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "BYPASS"
				) -or
				(
					$Server -eq $s2 -and
					($Body | ConvertFrom-Json).device_id -eq 5765373 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "BYPASS"
				)
			}
			$d = Set-CbcDevice -Device @($device1, $device2) -BypassEnabled $true
			$d.Count | Should -Be 2
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
			$d[1].Server | Should -Be $s2
			$d[1].Id | Should -Be 5765373
		}

		It "Should disable bypass the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id -eq 3 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "BYPASS"
				)
			}
			$d = Set-CbcDevice -Device $device1 -BypassEnabled $false
			$d.Count | Should -Be 1
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
		}

		It "Should disable bypass the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
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
				(
					(($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id -and $Server -eq $s1) -or
				    (($Body | ConvertFrom-Json).criteria.id[0] -eq $device2.Id -and $Server -eq $s2)
				)
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				(
					$Server -eq $s1 -and
					($Body | ConvertFrom-Json).device_id -eq 3 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "BYPASS"
				) -or
				(
					$Server -eq $s2 -and
					($Body | ConvertFrom-Json).device_id -eq 5765373 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "BYPASS"
				)
			}
			$d = Set-CbcDevice -Device @($device1, $device2) -BypassEnabled $false
			$d.Count | Should -Be 2
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
			$d[1].Server | Should -Be $s2
			$d[1].Id | Should -Be 5765373
		}

		It "Should update the policy of the device using PolicyId" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 3 -and
					($Body | ConvertFrom-Json).options.policy_id -eq 1 -and
					($Body | ConvertFrom-Json).action_type -eq "UPDATE_POLICY"
				)
			}

			$d = Set-CbcDevice -Device $device1 -PolicyId "1"
			$d.Count | Should -Be 1
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
		}

		It "Should update the policy of the device using Policy object" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
				$Method -eq "POST" -and
				($Body | ConvertFrom-Json).criteria.id[0] -eq $device1.Id
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 3 -and
					($Body | ConvertFrom-Json).options.policy_id -eq 1 -and
					($Body | ConvertFrom-Json).action_type -eq "UPDATE_POLICY"
				)
			}
			$Policy = [CbcPolicy]::new(
				1,
				"test",
				"test",
				1,
				15,
				1,
				$true,
				$s1
			)
			$d = Set-CbcDevice -Device $device1 -Policy $Policy
			$d.Count | Should -Be 1
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
		}
	}

	Context "When using `DeviceId` param" {
		It "Should quarantine the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				if ($Server -eq $s1) {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
					}	
				}
				else {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/device_api/no_devices.json"
					}
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
				$Method -eq "POST"
				($Body | ConvertFrom-Json).criteria.id -eq 3
			}

			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 204
					Content    = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id -eq 3 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "QUARANTINE"
				)
			}
			$d = Set-CbcDevice -Id "3" -QuarantineEnabled $true
			$d.Count | Should -Be 1
			$d[0].Server | Should -Be $s1
			$d[0].Id | Should -Be 3
		}
	}
}
