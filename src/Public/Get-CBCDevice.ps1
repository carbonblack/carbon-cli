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
.PARAMETER Filter
Set the filter in lucene syntax for the search.
.PARAMETER MaxResults
Set the max num of returned rows (default is 50 and max is 10k).
.PARAMETER Server
Sets a specified CBC Server from the current connections to execute the cmdlet with.
.OUTPUTS
CBCDevice[]
.EXAMPLE
PS > Get-CBCDevice

Returns all devices

If you have multiple connections and you want devices from a specific server
you can add the `-Server` param.

PS > Get-CBCDevice -Server $SpecifiedServer
.EXAMPLE
PS > Get-CBCDevice -Id "{DEVICE_ID}"

Returns the device with specified id.

If you have multiple connections and you want devices from a specific server
you can add the `-Server` param.

PS > Get-CBCDevice "{DEVICE_ID}" -Server $SpecifiedServer
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

PS > Get-CBCDevice -Include $Criteria
PS > Get-CBCDevice -Exclude $Exclusions
PS > Get-CBCDevice -Include $Criteria -Exclude $Exclusions
PS > Get-CBCDevice -Include $Criteria -Exclude $Exclusions -MaxResults 50
PS > Get-CBCDevice -Include @{"os"= @("WINDOWS")}

Returns all devices which correspond to the specified $Crtieria/$Exclusions.

If you have multiple connections and you want devices from a specific server
you can add the `-Server` param.

PS > Get-CBCDevice -Include $Criteria -Server $SpecifiedServer
.EXAMPLE
PS > Get-CBCDevice -Filter "os:WINDOWS"
PS > Get-CBCDevice -Filter "os:WINDOWS" -MaxResults 50

Returns all devices which correspond to the specified filter with lucene syntax.

If you have multiple connections and you want devices from a specific server
you can add the `-Server` param.

PS > Get-CBCDevice -Filter "os:WINDOWS" -MaxResults 50 -Server $SpecifiedServer
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/devices-api/
#>
function Get-CBCDevice {
	[CmdletBinding(DefaultParameterSetName = "default")]
	param(
		[Parameter(ParameterSetName = "id",Position = 0)]
		[array]$Id,

		[Parameter(ParameterSetName = "default")]
		[hashtable]$Include,

		[Parameter(ParameterSetName = "default")]
		[hashtable]$Exclude,

		[Parameter(ParameterSetName = "query")]
		[string]$Filter,

		[Parameter(ParameterSetName = "query")]
		[Parameter(ParameterSetName = "default")]
		[Parameter(ParameterSetName = "id")]
		[CBCServer[]]$Servers,

		[Parameter(ParameterSetName = "query")]
		[Parameter(ParameterSetName = "default")]
		[int32]$MaxResults
	)

	begin {
		Write-Verbose "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {

		if ($Servers) {
			$ExecuteServers = $Servers
		} else {
			$ExecuteServers = $global:CBC_CONFIG.currentConnections
		}

		switch ($PSCmdlet.ParameterSetName) {
			"default" {
				$Devices = @()
				$ExecuteServers | ForEach-Object {
					$CurrentServer = $_

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

					$RequestBody = ($RequestBody | ConvertTo-Json)

					Write-Debug "Invoking $CurrentServer"
					Write-Debug $("Endpoint {0}" -f $global:CBC_CONFIG.endpoints["Devices"]["Search"])
					Write-Debug "With Request Body: `r`n $RequestBody"

					$Response = Invoke-CBCRequest -Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Search"] `
						-Method POST `
						-Server $CurrentServer `
						-Body $RequestBody

					# Cast to Objects
					$JsonContent = $Response.Content | ConvertFrom-Json

					$JsonContent.results | ForEach-Object {
						$Devices += [CBCDevice]::new(
							$_.id,
							$_.status,
							$_.group,
							$_.policy_name,
							$_.target_priority,
							$_.email,
							$_.name,
							$_.os,
							$_.last_contact_time,
							$CurrentServer
						)
					}
				}
				return $Devices
			}
			"id" {
				$Devices = @()
				$ExecuteServers | ForEach-Object {
					$CurrentServer = $_

					$Response = Invoke-CBCRequest -Endpoint $global:CBC_CONFIG.endpoints["Devices"]["SpecificDeviceInfo"] `
						-Method GET `
						-Server $CurrentServer `
						-Params @($Id)

					# Cast to Objects
					$RawDeviceJson = $Response.Content | ConvertFrom-Json

					$Devices += [CBCDevice]::new(
						$RawDeviceJson.id,
						$RawDeviceJson.status,
						$RawDeviceJson.group,
						$RawDeviceJson.policy_name,
						$RawDeviceJson.target_priority,
						$RawDeviceJson.email,
						$RawDeviceJson.name,
						$RawDeviceJson.os,
						$RawDeviceJson.last_contact_time,
						$CurrentServer
					)
				}
				return $Devices
			}
			"query" {
				$Devices = @()
				$ExecuteServers | ForEach-Object {
					$CurrentServer = $_

					$RequestBody = @{
						query = $Filter
					}

					if ($MaxResults) {
						$RequestBody.rows = $MaxResults
					} else {
						$RequestBody.rows = 50
					}

					$RequestBody = $RequestBody | ConvertTo-Json

					Write-Debug "Invoking $CurrentServer"
					Write-Debug $("Endpoint {0}" -f $global:CBC_CONFIG.endpoints["Devices"]["Search"])
					Write-Debug "With Request Body: `r`n $RequestBody"

					$Response = Invoke-CBCRequest -Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Search"] `
						-Method POST `
						-Server $CurrentServer `
						-Body $RequestBody

					# Cast to Objects
					$JsonContent = $Response.Content | ConvertFrom-Json

					$JsonContent.results | ForEach-Object {
						$Devices += [CBCDevice]::new(
							$_.id,
							$_.status,
							$_.group,
							$_.policy_name,
							$_.target_priority,
							$_.email,
							$_.name,
							$_.os,
							$_.last_contact_time,
							$CurrentServer
						)
					}
				}
				return $Devices
			}

		}
	}

	end {
		Write-Verbose "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
