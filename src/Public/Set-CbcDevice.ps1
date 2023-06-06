using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet is used to update, configure and set the state of a device.
.SYNOPSIS
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
PS > Get-CBCDevice -Id 9187873 | Set-CbcDevice -Scan

Issuing a background scan on the device
.EXAMPLE
PS > $device = Get-CBCDevice -Id 9187873
PS > Set-CbcDevice -Device $device -PauseScan

Pausing a background scan on the device
.EXAMPLE
PS > Set-CbcDevice -Id 9187873 -BypassEnabled $true
Bypassing the device

.EXAMPLE
PS > Get-CBCDevice 9187873 | Set-CbcDevice -Device $device -QuarantineEnabled $true

Quarantine/Unquarantine the device

.EXAMPLE
PS > Set-CbcDevice -Device $device -SensorVersion "1.2.3"

Updates the sensor of the device
.EXAMPLE
PS > Set-CbcDevice -Device $device -UninstallSensor

Uninstalls the sensor of the device
.EXAMPLE
PS > Set-CbcDevice -Device $device -Policy (Get-CbcPolicy -Name CompanyStandardPolicy) 

PS > Set-CbcDevice -Device $device -PolicyId 15

Updates a policy of a device
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/devices-api/
#>

function Set-CbcDevice {
	[CmdletBinding(DefaultParameterSetName = "Device")]
	param(

		[Parameter(ValueFromPipeline = $true,
			Mandatory = $true,
			Position = 0,
			ParameterSetName = "Device")]
		[CbcDevice[]]$Device,

		[Parameter(
			ValueFromPipeline = $true,
			Mandatory = $true,
			Position = 0,
			ParameterSetName = "Id")]
		[int32[]]$Id,

		[ValidateNotNullOrEmpty()]
		[Parameter(ParameterSetName = "Device")]
		[Parameter(ParameterSetName = "Id")]
		[CbcPolicy[]]$Policy,

		[ValidateNotNullOrEmpty()]
		[Parameter(ParameterSetName = "Device")]
		[Parameter(ParameterSetName = "Id")]
		[array]$PolicyId,

		[ValidateNotNullOrEmpty()]
		[Parameter(ParameterSetName = "Device")]
		[Parameter(ParameterSetName = "Id")]
		[bool]$QuarantineEnabled,

		[ValidateNotNullOrEmpty()]
		[Parameter(ParameterSetName = "Device")]
		[Parameter(ParameterSetName = "Id")]
		[string]$SensorVersion,

		[ValidateNotNullOrEmpty()]
		[Parameter(ParameterSetName = "Device")]
		[Parameter(ParameterSetName = "Id")]
		[switch]$UninstallSensor,

		[ValidateNotNullOrEmpty()]
		[Parameter(ParameterSetName = "Device")]
		[Parameter(ParameterSetName = "Id")]
		[bool]$ScanEnabled,

		[ValidateNotNullOrEmpty()]
		[Parameter(ParameterSetName = "Device")]
		[Parameter(ParameterSetName = "Id")]
		[bool]$BypassEnabled
	)

	begin {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {

		switch ($PSCmdlet.ParameterSetName) {
			"Id" {
				$Device = Get-CbcDevice -Id $Id
			}
		}
		$DeviceGroups = $Device | Group-Object -Property Server, SensorKitType

		foreach ($Group in $DeviceGroups) {
			$RequestBody = @{}
			$RequestBody.device_id = @()
			foreach ($CurrDevice in $Group.Group) {
				Write-Warning "$($CurrDevice.Id) $($CurrDevice.Server) $($CurrDevice.SensorKitType)"
				$RequestBody.device_id += $CurrDevice.Id
				$CurrentServer = $CurrDevice.Server
				# get the sensorkittype for random device - they should be of the same sensorkittype
				$SensorKitType = $CurrDevice.SensorKitType
			}
			if ($PSBoundParameters.ContainsKey("QuarantineEnabled")) {
				$RequestBody.action_type = "QUARANTINE"
				$RequestBody.options = @{
					toggle = ($QuarantineEnabled ? "ON" : "OFF")
				}
			}
			elseif ($PSBoundParameters.ContainsKey("ScanEnabled")) {
				$RequestBody.action_type = "BACKGROUND_SCAN"
				$RequestBody.options = @{
					toggle = ($ScanEnabled ? "ON" : "OFF")
				}
			}
			elseif ($PSBoundParameters.ContainsKey("SensorVersion")) {
				$RequestBody.action_type = "UPDATE_SENSOR_VERSION"
				$RequestBody.options = @{
					sensor_version = @{
						$SensorKitType = $SensorVersion
					}
				}
			}
			elseif ($PSBoundParameters.ContainsKey("UninstallSensor")) {
				$RequestBody.action_type = "UNINSTALL_SENSOR"
			}
			elseif ($PSBoundParameters.ContainsKey("BypassEnabled")) {
				$RequestBody.action_type = "BYPASS"
				$RequestBody.options = @{
					toggle = ($BypassEnabled ? "ON" : "OFF")
				}
			}
			elseif ($PSBoundParameters.ContainsKey("Policy")) {
				$RequestBody.action_type = "UPDATE_POLICY"
				$RequestBody.options = @{
					policy_id = ($Policy | ForEach-Object { $_.Id })
				}
			}
			elseif ($PSBoundParameters.ContainsKey("PolicyId")) {
				$RequestBody.action_type = "UPDATE_POLICY"
				$RequestBody.options = @{
					policy_id = $PolicyId
				}
			}
			$JsonBody = $RequestBody | ConvertTo-Json
			$Response = Invoke-CbcRequest -Server $CurrentServer `
				-Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Actions"] `
				-Method POST `
				-Body $JsonBody
			if ($Response.StatusCode -ne 204) {
				Write-Error -Message $("Cannot complete action $($RequestBody.action_type) for devices $($RequestBody.device_id) for $($_)")
			}
			else {
				return Get-CbcDevice -Id @($RequestBody.device_id)
			}
		}
	}
	end {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
