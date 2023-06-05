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
.EXAMPLE
PS > Set-CbcDevice -Device $device -Policy $policy
PS > Get-CbcDevice "ID" |  Set-CbcDevice -Policy $policy

PS > Set-CbcDevice -Device $device -PolicyId 15
PS > Get-CbcDevice "ID" |  Set-CbcDevice -PolicyId 15

Updates a policy of a device
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/devices-api/
#>

function Set-CbcDevice {
	[CmdletBinding(DefaultParameterSetName = "default")]
	param(

		[Parameter(ValueFromPipeline = $true,
			Mandatory = $true,
			Position = 0,
			ParameterSetName = "Device")]
		[CbcDevice[]]$Device,

		[Parameter(ValueFromPipeline = $true,
			Mandatory = $true,
			Position = 0,
			ParameterSetName = "Id")]
		[array]$Id,

		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipeline = $true)]
		[CbcPolicy[]]$Policy,

		[ValidateNotNullOrEmpty()]
		[Parameter(ValueFromPipeline = $true)]
		[array]$PolicyId,

		[ValidateNotNullOrEmpty()]
		[bool]$QuarantineEnabled,

		[ValidateNotNullOrEmpty()]
		[string]$SensorVersion,

		[ValidateNotNullOrEmpty()]
		[switch]$UninstallSensor,

		[ValidateNotNullOrEmpty()]
		[bool]$ScanEnabled,

		[ValidateNotNullOrEmpty()]
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
		$UpdatedDevices = @()
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
				Write-Error -Message $("Cannot complete action $($RequestBody.action_type) for devices $($RequestBody.device_id) for $($CurrentServer)")
			}
			else {
				$UpdatedDevices += Get-CbcDevice -Id @($RequestBody.device_id) -Server $CurrentServer
			}
		}
		return $UpdatedDevices
	}
	end {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
