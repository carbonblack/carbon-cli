using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all devices or a specific device.
.SYNOPSIS
This cmdlet returns all devices or a specific device.
.PARAMETER Exclude
Sets the exclusions for the search.
.PARAMETER Id
Returns the devices with the specified Ids.
.PARAMETER Include
Sets the criteria for the search.
.PARAMETER MaxResults
Set the max number of results (default is 50 and max is 10k).
.PARAMETER Os
Specifies the Operating system to match.
Supported Os values: WINDOWS, LINUX, CENTOS, RHEL, ORACLE, SLES AMAZON_LINUX, SUSE, UBUNTU.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet against.
.PARAMETER Status
Specifies the status to match.
Supported Status values: PENDING, REGISTERED, UNINSTALLED, DEREGISTERED, ACTIVE, INACTIVE, ERROR, ALL, BYPASS_ON,
BYPASS, QUARANTINE, SENSOR_OUTOFDATE, DELETED, LIVE.
.PARAMETER TargetPriority
Specifies the Target priority to match.
Supported Target priority values: LOW, MEDIUM, HIGH, MISSION_CRITICAL.
.OUTPUTS
CbcDevice[]
.NOTES
Permissions needed: READ device
.EXAMPLE
PS > Get-CbcDevice

Returns all devices.

If you have multiple connections and you want devices from a specific connection
you can add the `-Server` param.

PS > Get-CbcDevice -Server $SpecifiedServer

.EXAMPLE
PS > Get-CbcDevice -Id 2345,7368

Returns devices with the specified Ids

.EXAMPLE
PS > Get-CbcDevice -Os Windows,Linux

Returns the devices with either Windows or Linux operating systems.

.EXAMPLE
PS > Get-CbcDevice -Os Windows -Status REGISTERED

Returns all Windows devices that are in status: REGISTERED.

.EXAMPLE
PS > Get-CbcDevice -Os Linux -Priority HIGH -Status ERROR

Returns all Linux devices devices that are in status ERROR and have HIGH priority.

.EXAMPLE
$IncludeCriteria = @{
      "ad_group_id"= @( <long>, <long>)
      "auto_scaling_group_name"= @( "<string>", "<string>")
      "base_device": <boolean>
      "cloud_provider_account_id"= @( "<string>", "<string>")
      "cloud_provider_resource_id"= @( "<string>", "<string>")
      "cloud_provider_tags"= @( "<string>", "<string>")
      "deployment_type"= @( "<string>", "<string>")
      "golden_device_id"= @( "<string>", "<string>")
      "golden_device_status"= @( "<string>", "<string>")
      "host_based_firewall_status"= @( "<string>", "<string>")
      "host_based_firewall_reason": "<string>"
      "id"= @( <long>, <long>)
      "infrastructure_provider"= @( "<string>", "<string>")
      "last_contact_time": {
        "end": "<dateTime>",
        "range": "<string>",
        "start": "<dateTime>"
      }
      "os"= @( "<string>", "<string>")
      "os_version"= @( "<string>", "<string>")
      "policy_id"= @( <long>, <long>)
      "sensor_version"= @( "<string>", "<string>")
      "signature_status"= @( "<string>", "<string>")
      "status"= @( "<string>", "<string>")
      "sub_deployment_type"= @( "<string>", "<string>")
      "target_priority"= @( "<string>", "<string>")
      "vcenter_uuid"= @( "<string>", "<string>")
      "virtual_private_cloud_id"= @( "<string>", "<string>")
      "virtualization_provider"= @( "<string>", "<string>")
      "vm_uuid"= @( "<string>", "<string>")
      "vcenter_host_url"= @( "<string>", "<string>" )
}

Currently only the `sensor_version` is supported as an exclusion field.

$ExcludeCriteria = @{
    "sensor_version" = @("<string>")
}

Both Include and Exclude parameters expect a hash table object.

PS > $ExcludeCriteria = @{"sensor_version" = @("windows:3.9.2.2637")}
PS > $IncludeCriteria = @{"os" = @("WINDOWS")}
PS > Get-CbcDevice -Include $IncludeCriteria -Exclude $ExcludeCriteria -MaxResults 50

Get all windows devices that are not on sensor version 3.9.2.2637. The sensor version should be passed in the format:
<os>:#.#.#.#.

PS > $IncludeCriteria = @{}
PS > $IncludeCriteria.os = @("Linux")
PS > $IncludeCriteria.target_priority = @("Low")
PS > Get-CbcDevice -Include $IncludeCriteria

Returns all devices which correspond to the specified include criteria.

.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/devices-api/
#>

function Get-CbcDevice {

	[CmdletBinding(DefaultParameterSetName = "Default")]
	[OutputType([CbcDevice[]])]
	param(
		[Parameter(ParameterSetName = "IncludeExclude")]
		[hashtable]$Exclude,

		[Parameter(ParameterSetName = "Id", Position = 0)]
		[long[]]$Id,

		[Parameter(ParameterSetName = "IncludeExclude")]
		[hashtable]$Include,

		[Parameter(ParameterSetName = "Default")]
		[Parameter(ParameterSetName = "IncludeExclude")]
		[int32]$MaxResults = 50,

		[Parameter(ParameterSetName = "Default")]
		[string[]]$Os,

		[Parameter(ParameterSetName = "Default")]
		[string[]]$OsVersion,

		[Parameter(ParameterSetName = "Default")]
		[Parameter(ParameterSetName = "IncludeExclude")]
		[Parameter(ParameterSetName = "Id")]
		[CbcServer[]]$Server,

		[Parameter(ParameterSetName = "Default")]
		[string[]]$Status,

		[Parameter(ParameterSetName = "Default")]
		[string[]]$TargetPriority
	)

	begin {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {

		if ($Server) {
			$ExecuteServers = $Server
		}
		else {
			$ExecuteServers = $global:DefaultCbcServers
		}
		switch ($PSCmdlet.ParameterSetName) {
			"Default" {
				$ExecuteServers | ForEach-Object {
					$CurrentServer = $_
					$RequestBody = @{}
					$RequestBody.criteria = @{}

					if ($PSBoundParameters.ContainsKey("Os")) {
						$RequestBody.criteria.os = $Os
					}

					if ($PSBoundParameters.ContainsKey("OsVersion")) {
						$RequestBody.criteria.os_version = $OsVersion
					}

					if ($PSBoundParameters.ContainsKey("Status")) {
						$RequestBody.criteria.status = $Status
					}

					if ($PSBoundParameters.ContainsKey("TargetPriority")) {
						$RequestBody.criteria.target_priority = $TargetPriority
					}

					$RequestBody.rows = $MaxResults

					$RequestBody = $RequestBody | ConvertTo-Json

					$Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Search"] `
						-Method POST `
						-Server $_ `
						-Body $RequestBody

					if ($Response.StatusCode -ne 200) {
						Write-Error -Message $("Cannot get devices for $($_)")
					}
					else {
						$JsonContent = $Response.Content | ConvertFrom-Json

						$JsonContent.results | ForEach-Object {
							return Initialize-CbcDevice $_ $CurrentServer
						}
					}
				}
			}
			"IncludeExclude" {
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

					if ($Response.StatusCode -ne 200) {
						Write-Error -Message $("Cannot get devices for $($_)")
					}
					else {
						$JsonContent = $Response.Content | ConvertFrom-Json

						$JsonContent.results | ForEach-Object {
							return Initialize-CbcDevice $_ $CurrentServer
						}
					}
				}
			}
			"Id" {
				$ExecuteServers | ForEach-Object {
					$CurrentServer = $_
					$RequestBody = @{}
					$RequestBody.rows = $MaxResults
					$RequestBody.criteria = @{"id" = $Id }
					$RequestBody = $RequestBody | ConvertTo-Json

					$Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Devices"]["Search"] `
						-Method POST `
						-Server $_ `
						-Body $RequestBody
					
					if ($Response.StatusCode -ne 200) {
						Write-Error -Message $("Cannot get devices for $($_)")
					}
					else {
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
