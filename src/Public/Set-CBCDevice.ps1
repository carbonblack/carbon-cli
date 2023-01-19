using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet is used to update, configure and set the state of a device.

.PARAMETER Device
An array of CbcDevice object types.
.PARAMETER Scan
To execute a background scan on the device.
.PARAMETER PauseScan
To pause a background scan on the device.
.PARAMETER BypassEnabled
To bypass the device.
.PARAMETER QuarantineEnabled
To quarantine/unquarantine the device.
.PARAMETER UpdateSensor
To update the sensor of the device to a specific version.
.PARAMETER UninstallSensor
To uninstall the sensor of the device
.OUTPUTS
CbcDevice[]
.EXAMPLE
PS > Set-CbcDevice -Device $device -Scan
PS > Get-CbcDevice "ID" | Set-CbcDevice -Scan

Issuing a background scan on the device
.EXAMPLE
PS > Set-CbcDevice -Device $device -PauseScan
PS > Get-CbcDevice "ID" | Set-CbcDevice -PauseScan

Pausing a background scan on the device
.EXAMPLE
PS > Set-CbcDevice -Device $device -BypassEnabled $true
PS > Get-CbcDevice "ID" | Set-CbcDevice -BypassEnabled $false

Bypassing the device
.EXAMPLE
PS > Set-CbcDevice -Device $device -QuarantineEnabled $true
PS > Get-CbcDevice "ID" | Set-CbcDevice -QuarantineEnabled $false

Quarantine/Unquarantine the device
.EXAMPLE
PS > Set-CbcDevice -Device $device -SensorVersion "1.2.3"
PS > Get-CbcDevice "ID" | Set-CbcDevice -SensorVersion "1.2.3"

Updates the sensor of the device
.EXAMPLE
PS > Set-CbcDevice -Device $device -UninstallSensor
PS > Get-CbcDevice "ID" | Set-CbcDevice -UninstallSensor

Uninstalls the sensor of the device
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/devices-api/
#>

function Set-CBCDevice {
	[CmdletBinding(DefaultParameterSetName = "default")]
	param(
		[Parameter(ValueFromPipeline = $true,Mandatory = $true,Position = 0)]
		[CbcDevice[]]$Device,
		[CbcPolicy]$Policy,# TODO: tests, examples
		[Parameter(ParameterSetName = "Quarantine")]
		[bool]$QuarantineEnabled,
		[Parameter(ParameterSetName = "UpdateSensor")]
		[string]$SensorVersion,
		[Parameter(ParameterSetName = "UninstallSensor")]
		[switch]$UninstallSensor,
		[Parameter(ParameterSetName = "Scan")]
		[bool]$ScanEnabled,
		[Parameter(ParameterSetName = "Bypass")]
		[bool]$BypassEnabled
	)

	begin {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {

		switch ($PSCmdlet.ParameterSetName) {
			"Quarantine" {
				$Device | ForEach-Object {
					$RequestBody = @{}
					$RequestBody.action_type = "QUARANTINE"
					$RequestBody.options = @{
						toggle = ($QuarantineEnabled ? "ON" : "OFF")
					}
					$RequestBody.device_id = @($_.id)
					$JsonBody = $RequestBody | ConvertTo-Json
					$Response = Invoke-CBCRequest -Server $_.CBCServer `
						 -Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Actions"] `
						 -Method POST `
						 -Body $JsonBody

					if ($Response.StatusCode -ne 204) {
						Write-Error -Message $("Cannot quarantine the device {0}" -f $_.id)
					} else {
						return $_
					}
				}
			}
			"UpdateSensor" {
				$Device | ForEach-Object {
					$RequestBody = @{}
					$RequestBody.action_type = "UPDATE_SENSOR_VERSION"
					$RequestBody.options = @{
						sensor_version = @{
							$_.SensorKitType = $SensorVersion
						}
					}
					$RequestBody.device_id = @($_.id)
					$JsonBody = $RequestBody | ConvertTo-Json
					$Response = Invoke-CBCRequest -Server $_.CBCServer `
						 -Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Actions"] `
						 -Method POST `
						 -Body $JsonBody

					if ($Response.StatusCode -ne 204) {
						Write-Error -Message $("Cannot update the sensor of the device {0}" -f $_.id)
					} else {
						return $_
					}
				}
			}
			"UninstallSensor" {
				$Device | ForEach-Object {
					$RequestBody = @{}
					$RequestBody.action_type = "UNINSTALL_SENSOR"
					$RequestBody.device_id = @($_.id)
					$JsonBody = $RequestBody | ConvertTo-Json
					$Response = Invoke-CBCRequest -Server $_.CBCServer `
							-Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Actions"] `
							-Method POST `
							-Body $JsonBody

					if ($Response.StatusCode -ne 204) {
						Write-Error -Message $("Cannot uninstall the sensor on the device {0}" -f $_.id)
					} else {
						return $_
					}
				}
			}
			"Scan" {
				$Device | ForEach-Object {
					$RequestBody = @{}
					$RequestBody.action_type = "BACKGROUND_SCAN"
					$RequestBody.options = @{
						toggle = ($ScanEnabled ? "ON" : "OFF")
					}
					$RequestBody.device_id = @($_.id)
					$JsonBody = $RequestBody | ConvertTo-Json
					$Response = Invoke-CBCRequest -Server $_.CBCServer `
							-Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Actions"] `
							-Method POST `
							-Body $JsonBody
					if ($Response.StatusCode -ne 204) {
						Write-Debug "DGJKDFSGJKFSJGFSGJSF"
						Write-Error -Message $("Cannot scan the device {0}" -f $_.id)
					} else {
						return $_
					}
				}
			}
			"Bypass" {
				$Device | ForEach-Object {
					$RequestBody = @{}
					$RequestBody.action_type = "BYPASS"
					$RequestBody.options = @{
						toggle = ($BypassEnabled ? "ON" : "OFF")
					}
					$RequestBody.device_id = @($_.id)
					$JsonBody = $RequestBody | ConvertTo-Json
					$Response = Invoke-CBCRequest -Server $_.CBCServer `
						 -Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Actions"] `
						 -Method POST `
						 -Body $JsonBody

					if ($Response.StatusCode -ne 204) {
						Write-Error -Message $("Cannot bypass the device {0}" -f $_.id)
					} else {
						return $_
					}
				}
			}
		}
	}

	end {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
