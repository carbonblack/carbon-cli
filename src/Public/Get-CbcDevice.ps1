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
Set the max number of results (default is 50 and max is 10k).
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.OUTPUTS
CbcDevice[]
.EXAMPLE
PS > Get-CbcDevice

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
PS > Get-CbcDevice -Include $Criteria -Exclude $Exclusions -MaxResults 50
PS > Get-CbcDevice -Include @{"os"= @("WINDOWS")}

Returns all devices which correspond to the specified $Crtieria/$Exclusions.

If you have multiple connections and you want devices from a specific server
you can add the `-Server` param.

PS > Get-CbcDevice -Include $Criteria -Server $SpecifiedServer
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/devices-api/
#>
function Get-CbcDevice {
	[CmdletBinding(DefaultParameterSetName = "Default")]
	[OutputType([CbcDevice[]])]
	param(
		[Parameter(ParameterSetName = "Id", Position = 0)]
		[array]$Id,

		[Parameter(ParameterSetName = "Default")]
		[hashtable]$Include,

		[Parameter(ParameterSetName = "Default")]
		[hashtable]$Exclude,

		[Parameter(ParameterSetName = "Default")]
		[Parameter(ParameterSetName = "Id")]
		[CbcServer[]]$Servers,

		[Parameter(ParameterSetName = "Default")]
		[int32]$MaxResults = 50
	)

	begin {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {

		if ($Servers) {
			$ExecuteServers = $Servers
		}
		else {
			$ExecuteServers = $global:CBC_CONFIG.currentConnections
		}
		switch ($PSCmdlet.ParameterSetName) {
			"Default" {
				$ExecuteServers | ForEach-Object {
					$CurrentServer = $_

					$RequestBody = @{}
					if ($Include) {
						$RequestBody.criteria = $Include
					}
					if ($Exclude) {
						$RequestBody.exclusions = $Exclude
					}
					$RequestBody.rows = $MaxResults

					$RequestBody = $RequestBody | ConvertTo-Json

					$Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Search"] `
						-Method POST `
						-Server $_ `
						-Body $RequestBody

					$JsonContent = $Response.Content | ConvertFrom-Json

					$JsonContent.results | ForEach-Object {
						return Initialize-CbcDevice $_ $CurrentServer
					}
				}
			}
			"Id" {
				$ExecuteServers | ForEach-Object {
					$CurrentServer = $_
					if ($Id -is [System.Object]) {
						$Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Details"] `
							-Method GET `
							-Server $_ `
							-Params $Id
						$JsonContent = $Response.Content | ConvertFrom-Json
						if ($null -ne $JsonContent) {
							return Initialize-CBCDevice $JsonContent $_
						}
						return $null
					}
					else {
						$RequestBody = @{}
						$RequestBody.rows = 10000
						$RequestBody.criteria = @{"id" = $Id }
						$RequestBody = $RequestBody | ConvertTo-Json

						$Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Search"] `
							-Method POST `
							-Server $_ `
							-Body $RequestBody

						$JsonContent = $Response.Content | ConvertFrom-Json

						$JsonContent.results | ForEach-Object {
							return Initialize-CbcDevice $_ $CurrentServer
						}
					}
				}
			}
		}
	}

	end {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
