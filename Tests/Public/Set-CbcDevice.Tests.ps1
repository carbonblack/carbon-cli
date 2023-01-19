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
			$s1
		)
		$device2 = [CbcDevice]::new(
			"2",
			"REGISTERED",
			"",
			"Standard",
			"MEDIUM",
			"Administrator",
			"Test",
			"WINDOWS",
			"01/12/2023 21:54:29",
			"RHEL",
			$s1
		)
	}

	Context "When using a `CbcDevice` object" {
		It "Should quarantine the device" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "toggle": "ON" }, "action_type": "QUARANTINE" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				$Body -eq $ExampleJsonBody
			}
			$d = Set-CbcDevice -Device $device1 -QuarantineEnabled $true
			$d | Should -Be $device1
		}
		It "Should quarantine the devices" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "toggle": "ON" }, "action_type": "QUARANTINE" }' | ConvertFrom-Json | ConvertTo-Json
			$ExampleJsonBody2 = '{"device_id": ["2"], "options": { "toggle": "ON" }, "action_type": "QUARANTINE" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				($Body -eq $ExampleJsonBody) -or ($Body -eq $ExampleJsonBody2)
			}

			$d = Set-CbcDevice -Device @($device1,$device2) -QuarantineEnabled $true
			$d | Should -Be @($device1,$device2)
		}
		It "Should unquarantine the device" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "toggle": "OFF" }, "action_type": "QUARANTINE" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				$Body -eq $ExampleJsonBody
			}
			$d = Set-CbcDevice -Device $device1 -QuarantineEnabled $false
			$d | Should -Be $device1
		}
		It "Should unquarantine the devices" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "toggle": "OFF" }, "action_type": "QUARANTINE" }' | ConvertFrom-Json | ConvertTo-Json
			$ExampleJsonBody2 = '{"device_id": ["2"], "options": { "toggle": "OFF" }, "action_type": "QUARANTINE" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				($Body -eq $ExampleJsonBody) -or ($Body -eq $ExampleJsonBody2)
			}

			$d = Set-CbcDevice -Device @($device1,$device2) -QuarantineEnabled $false
			$d | Should -Be @($device1,$device2)
		}
		It "Should scan the device" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "toggle": "ON" }, "action_type": "BACKGROUND_SCAN" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				$Body -eq $ExampleJsonBody
			}

			$d = Set-CbcDevice -Device $device1 -ScanEnabled $true
			$d | Should -Be $device1
		}
		It "Should scan the devices" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "toggle": "ON" }, "action_type": "BACKGROUND_SCAN" }' | ConvertFrom-Json | ConvertTo-Json
			$ExampleJsonBody2 = '{"device_id": ["2"], "options": { "toggle": "ON" }, "action_type": "BACKGROUND_SCAN" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				($Body -eq $ExampleJsonBody) -or ($Body -eq $ExampleJsonBody2)
			}

			$d = Set-CbcDevice -Device @($device1,$device2) -ScanEnabled $true
			$d | Should -Be @($device1,$device2)
		}
		It "Should pause the scan on the device" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "toggle": "OFF" }, "action_type": "BACKGROUND_SCAN" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				$Body -eq $ExampleJsonBody
			}

			$d = Set-CbcDevice -Device $device1 -ScanEnabled $false
			$d | Should -Be $device1
		}
		It "Should pause the scan on the devices" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "toggle": "OFF" }, "action_type": "BACKGROUND_SCAN" }' | ConvertFrom-Json | ConvertTo-Json
			$ExampleJsonBody2 = '{"device_id": ["2"], "options": { "toggle": "OFF" }, "action_type": "BACKGROUND_SCAN" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				($Body -eq $ExampleJsonBody) -or ($Body -eq $ExampleJsonBody2)
			}

			$d = Set-CbcDevice -Device @($device1,$device2) -ScanEnabled $false
			$d | Should -Be @($device1,$device2)
		}
		It "Should update the sensor of the device" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "sensor_version": {"SUSE": "2.4.0.3"}}, "action_type": "UPDATE_SENSOR_VERSION" }' | ConvertFrom-Json | ConvertTo-Json
			$ExampleJsonBody2 = '{"device_id": ["2"], "options": { "sensor_version": {"RHEL": "2.4.0.3"}}, "action_type": "UPDATE_SENSOR_VERSION" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				($Body -eq $ExampleJsonBody) -or ($Body -eq $ExampleJsonBody2)
			}
			$d = Set-CbcDevice -Device @($device1,$device2) -SensorVersion "2.4.0.3"
			$d | Should -Be @($device1,$device2)
		}
		It "Should update the sensor of the devices" {
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
				$Body -eq $ExampleJsonBody
			}
			$d = Set-CbcDevice -Device $device1 -SensorVersion "2.4.0.3"
			$d | Should -Be $device1
		}
		It "Should uninstall the sensor of the device" {
			$ExampleJsonBody = '{"device_id": ["1"], "action_type": "UNINSTALL_SENSOR" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				$Body -eq $ExampleJsonBody
			}
			$d = Set-CbcDevice -Device $device1 -UninstallSensor
			$d | Should -Be $device1
		}
		It "Should uninstall the sensor of the devices" {
			$ExampleJsonBody = '{"device_id": ["1"], "action_type": "UNINSTALL_SENSOR" }' | ConvertFrom-Json | ConvertTo-Json
			$ExampleJsonBody2 = '{"device_id": ["2"], "action_type": "UNINSTALL_SENSOR" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				($Body -eq $ExampleJsonBody) -or ($Body -eq $ExampleJsonBody2)
			}
			$d = Set-CbcDevice -Device @($device1,$device2) -UninstallSensor
			$d | Should -Be @($device1,$device2)
		}
		It "Should enable bypass the device" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "toggle": "ON" }, "action_type": "BYPASS" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				$Body -eq $ExampleJsonBody
			}
			$d = Set-CbcDevice -Device $device1 -BypassEnabled $true
			$d | Should -Be $device1
		}
		It "Should enable bypass the devices" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "toggle": "ON" }, "action_type": "BYPASS" }' | ConvertFrom-Json | ConvertTo-Json
			$ExampleJsonBody2 = '{"device_id": ["2"], "options": { "toggle": "ON" }, "action_type": "BYPASS" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				($Body -eq $ExampleJsonBody) -or ($Body -eq $ExampleJsonBody2)
			}
			$d = Set-CbcDevice -Device @($device1,$device2) -BypassEnabled $true
			$d | Should -Be @($device1,$device2)
		}
		It "Should disable bypass the device" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "toggle": "OFF" }, "action_type": "BYPASS" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				$Body -eq $ExampleJsonBody
			}
			$d = Set-CbcDevice -Device $device1 -BypassEnabled $false
			$d | Should -Be $device1
		}
		It "Should disable bypass the devices" {
			$ExampleJsonBody = '{"device_id": ["1"], "options": { "toggle": "OFF" }, "action_type": "BYPASS" }' | ConvertFrom-Json | ConvertTo-Json
			$ExampleJsonBody2 = '{"device_id": ["2"], "options": { "toggle": "OFF" }, "action_type": "BYPASS" }' | ConvertFrom-Json | ConvertTo-Json
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				return @{
					StatusCode = 204
					Content = ""
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Actions"] -and
				$Method -eq "POST" -and
				$Server -eq $s1 -and
				($Body -eq $ExampleJsonBody) -or ($Body -eq $ExampleJsonBody2)
			}
			$d = Set-CbcDevice @($device1,$device2) -BypassEnabled $false
			$d | Should -Be @($device1,$device2)
		}
	}
	Context "When using a `String` for -Device" {
	}
	Context "When using the pipe" {

	}

}
