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
		$s1 = [CbcServer]::new("https://t.te/","test","test")
		$s2 = [CbcServer]::new("https://t.te2/","test2","test2")
		$global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
		$global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
		$global:CBC_CONFIG.currentConnections.Add($s2) | Out-Null

		$device1 = [CbcDevice]::new(
			"1",
			"REGISTERED",
			"",
			"Standard",
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
			"2",
			"REGISTERED",
			"",
			"Standard",
			"MEDIUM",
			"Administrator",
			"Test",
			"RHEL",
			"01/12/2023 21:54:29",
			"RHEL",
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
		It "Should quarantine the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "QUARANTINE"
				)
			}
			$d = Set-CbcDevice -Device $device1 -QuarantineEnabled $true
			$d | Should -Be $device1
		}
		It "Should quarantine the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "QUARANTINE"
				) -or
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 2 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "QUARANTINE"
				)
			}

			$d = Set-CbcDevice -Device @($device1,$device2) -QuarantineEnabled $true
			$d | Should -Be @($device1,$device2)
		}
		It "Should unquarantine the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "QUARANTINE"
				)
			}
			$d = Set-CbcDevice -Device $device1 -QuarantineEnabled $false
			$d | Should -Be $device1
		}
		It "Should unquarantine the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "QUARANTINE"
				) -or
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 2 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "QUARANTINE"
				)
			}

			$d = Set-CbcDevice -Device @($device1,$device2) -QuarantineEnabled $false
			$d | Should -Be @($device1,$device2)
		}
		It "Should scan the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "BACKGROUND_SCAN"
				)
			}

			$d = Set-CbcDevice -Device $device1 -ScanEnabled $true
			$d | Should -Be $device1
		}
		It "Should scan the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "BACKGROUND_SCAN"
				) -or
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 2 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "BACKGROUND_SCAN"
				)
			}

			$d = Set-CbcDevice -Device @($device1,$device2) -ScanEnabled $true
			$d | Should -Be @($device1,$device2)
		}
		It "Should pause the scan on the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "BACKGROUND_SCAN"
				)
			}

			$d = Set-CbcDevice -Device $device1 -ScanEnabled $false
			$d | Should -Be $device1
		}
		It "Should pause the scan on the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "BACKGROUND_SCAN"
				) -or
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 2 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "BACKGROUND_SCAN"
				)
			}

			$d = Set-CbcDevice -Device @($device1,$device2) -ScanEnabled $false
			$d | Should -Be @($device1,$device2)
		}
		It "Should update the sensor of the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.sensor_version.SUSE -eq "2.4.0.3" -and
					($Body | ConvertFrom-Json).action_type -eq "UPDATE_SENSOR_VERSION"
				) -or
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 2 -and
					($Body | ConvertFrom-Json).options.sensor_version.RHEL -eq "2.4.0.3" -and
					($Body | ConvertFrom-Json).action_type -eq "UPDATE_SENSOR_VERSION"
				)
			}
			$d = Set-CbcDevice -Device @($device1,$device2) -SensorVersion "2.4.0.3"
			$d | Should -Be @($device1,$device2)
		}
		It "Should update the sensor of the device" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "sensor_version": {"SUSE": "2.4.0.3"}}, "action_type": "UPDATE_SENSOR_VERSION" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.sensor_version.SUSE -eq "2.4.0.3" -and
					($Body | ConvertFrom-Json).action_type -eq "UPDATE_SENSOR_VERSION"
				)
			}
			$d = Set-CbcDevice -Device $device1 -SensorVersion "2.4.0.3"
			$d | Should -Be $device1
		}
		It "Should uninstall the sensor of the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).action_type -eq "UNINSTALL_SENSOR"
				)
			}
			$d = Set-CbcDevice -Device $device1 -UninstallSensor
			$d | Should -Be $device1
		}
		It "Should uninstall the sensor of the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).action_type -eq "UNINSTALL_SENSOR"
				) -or
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 2 -and
					($Body | ConvertFrom-Json).action_type -eq "UNINSTALL_SENSOR"
				)
			}
			$d = Set-CbcDevice -Device @($device1,$device2) -UninstallSensor
			$d | Should -Be @($device1,$device2)
		}
		It "Should enable bypass the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "BYPASS"
				)
			}
			$d = Set-CbcDevice -Device $device1 -BypassEnabled $true
			$d | Should -Be $device1
		}
		It "Should enable bypass the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "BYPASS"
				) -or
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 2 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "BYPASS"
				)
			}
			$d = Set-CbcDevice -Device @($device1,$device2) -BypassEnabled $true
			$d | Should -Be @($device1,$device2)
		}
		It "Should disable bypass the device" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "BYPASS"
				)
			}
			$d = Set-CbcDevice -Device $device1 -BypassEnabled $false
			$d | Should -Be $device1
		}
		It "Should disable bypass the devices" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "BYPASS"
				) -or
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 2 -and
					($Body | ConvertFrom-Json).options.toggle -eq "OFF" -and
					($Body | ConvertFrom-Json).action_type -eq "BYPASS"
				)
			}
			$d = Set-CbcDevice -Device @($device1,$device2) -BypassEnabled $false
			$d | Should -Be @($device1,$device2)
		}
	}
	Context "When using `DeviceId` param" {
		It "Should quarantine the device" {
			Mock Get-CbcDevice -ModuleName PSCarbonBlackCloud {
				return $device1
			} -ParameterFilter {
				$Id -eq 1
			}
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				(
					($Body | ConvertFrom-Json).device_id[0] -eq 1 -and
					($Body | ConvertFrom-Json).options.toggle -eq "ON" -and
					($Body | ConvertFrom-Json).action_type -eq "QUARANTINE"
				)
			}
			$d = Set-CbcDevice -Id "1" -QuarantineEnabled $true
			$d | Should -Be $device1
		}
	}
}
