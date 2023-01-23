using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all devices or a specific device.
.SYNOPSIS
This cmdlet returns all devices or a specific device.
.PARAMETER Id
Returns a device with specified ID.
.PARAMETER Include
Sets the criteria for the search.
.PARAMETER Exclude
Sets the exclusions for the search.
.PARAMETER MaxResults
Set the max num of returned rows (default is 50 and max is 10k).
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.OUTPUTS
CbcDevice[]
.EXAMPLE
PS > Get-CbcDevice | ft

Returns all devices

If you have multiple connections and you want devices from a specific server
you can add the `-Server` param.

PS > Get-CbcDevice -Server $SpecifiedServer
.EXAMPLE
PS > Get-CbcDevice -Id "{DEVICE_ID}"

Returns the device with specified id.

If you have multiple connections and you want devices from a specific server
you can add the `-Server` param.

PS > Get-CbcDevice "{DEVICE_ID}" -Server $SpecifiedServer
.EXAMPLE
$Criteria = @{
    "criteria" = @{
      "status" = [ "<string>", "<string>" ],
      "os" = [ "<string>", "<string>" ],
      "lastContactTime" = {
        "end" = "<dateTime>",
        "range" = "<string>",
        "start" = "<dateTime>"
      },
      "adGroupId" = [ "<long>", "<long>" ],
      "policyId" = [ "<long>", "<long>" ],
      "id" = [ "<long>", "<long>" ],
      "targetPriority" = [ "<string>", "<string>" ],
      "deploymentType" = [ "<string>", "<string>" ],
      "vmUuid" = [ "<string>", "<string>" ],
      "vcenterUuid" = [ "<string>", "<string>" ],
      "osVersion" = [ "<string>", "<string>" ],
      "sensorVersion" = [ "<string>", "<string>" ],
      "signatureStatus" = [ "<string>", "<string>" ],
      "goldenDeviceStatus" = [ "<string>", "<string>" ],
      "goldenDeviceId" = [ "<string>", "<string>" ],
      "cloudProviderTags" = [ "<string>", "<string>" ],
      "virtualPrivateCloudId" = [ "<string>", "<string>" ],
      "autoScalingGroupName" = [ "<string>", "<string>" ],
      "cloudProviderAccountId" = [ "<string>", "<string>" ],
      "cloudProviderResourceId" = [ "<string>", "<string>" ],
      "virtualizationProvider" = [ "<string>", "<string>" ],
      "subDeploymentType" = [ "<string>", "<string>" ],
      "baseDevice" = "<boolean>",
      "hostBasedFirewallStatus" = [ "<string>", "<string>" ],
      "hostBasedFirewallReason" = "<string>",
      "hostBasedFirewallSensorObservedState" = "<string>",
      "vcenterHostUrl" = [ "<string>", "<string>" ]
    }
}

Currently only the `sensor_version` is supported as an exclusion field.

$Exclusions = @{
    "exclusions" = {
      "sensor_version" = ["<string>"]
    }
}

PS > Get-CbcDevice -Include $Criteria
PS > Get-CbcDevice -Exclude $Exclusions
PS > Get-CbcDevice -Include $Criteria -Exclude $Exclusions
PS > Get-CbcDevice -Include $Criteria -Exclude $Exclusions -MaxResults 50 | ft
PS > Get-CbcDevice -Include @{"os"= @("WINDOWS")}

Returns all devices which correspond to the specified $Crtieria/$Exclusions.

If you have multiple connections and you want devices from a specific server
you can add the `-Server` param.

PS > Get-CbcDevice -Include $Criteria -Server $SpecifiedServer
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/devices-api/
#>
function Get-CbcDevice {
	[CmdletBinding(DefaultParameterSetName = "default")]
	param(
		[Parameter(ParameterSetName = "id",Position = 0)]
		[array]$Id,

		[Parameter(ParameterSetName = "default")]
		[hashtable]$Include,

		[Parameter(ParameterSetName = "default")]
		[hashtable]$Exclude,

		[Parameter(ParameterSetName = "query")]
		[Parameter(ParameterSetName = "default")]
		[Parameter(ParameterSetName = "id")]
		[CbcServer[]]$Servers,

		[Parameter(ParameterSetName = "query")]
		[Parameter(ParameterSetName = "default")]
		[int32]$MaxResults
	)

	begin {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {

		if ($Servers) {
			$ExecuteServers = $Servers
		} else {
			$ExecuteServers = $global:CBC_CONFIG.currentConnections
		}

		switch ($PSCmdlet.ParameterSetName) {
			"default" {
				$ExecuteServers | ForEach-Object {
					$RequestBody = @{}

					if ($Include) {
						$RequestBody.criteria = $Include
					}

					if ($Exclude) {
						$RequestBody.exclusions = $Exclude
					}

					if ($MaxResults) {
						$RequestBody.rows = $MaxResults
					} else {
						$RequestBody.rows = 50
					}

					$RequestBody = $RequestBody | ConvertTo-Json

					$Response = Invoke-CBCRequest -Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Search"] `
 						-Method POST `
 						-Server $_ `
 						-Body $RequestBody

					# Cast to Objects
					$JsonContent = $Response.Content | ConvertFrom-Json

					$CurrentServer = $_
					$JsonContent.results | ForEach-Object {
						return [CbcDevice]::new(
							$_.id,
							$_.status,
							$_.Group,
							$_.policy_name,
							$_.target_priority,
							$_.email,
							$_.Name,
							$_.os,
							$_.last_contact_time,
							$_.sensor_kit_type,
							$CurrentServer
						)
					}
				}
			}
			"id" {
				$ExecuteServers | ForEach-Object {

					$Response = Invoke-CBCRequest -Endpoint $global:CBC_CONFIG.endpoints["Devices"]["SpecificDeviceInfo"] `
 						-Method GET `
 						-Server $_ `
 						-Params @($Id)

					# Cast to Objects
					$RawDeviceJson = $Response.Content | ConvertFrom-Json

					return [CbcDevice]::new(
						$RawDeviceJson.id,
						$RawDeviceJson.status,
						$RawDeviceJson.Group,
						$RawDeviceJson.policy_name,
						$RawDeviceJson.target_priority,
						$RawDeviceJson.email,
						$RawDeviceJson.Name,
						$RawDeviceJson.os,
						$RawDeviceJson.last_contact_time,
						$RawDeviceJson.sensor_kit_type,
						$_
					)
				}
			}
		}
	}

	end {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
