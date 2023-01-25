using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all alerts or a specific alert with every current connection.
.SYNOPSIS
This cmdlet returns all alerts or a specific alert with every current connection.
.PARAMETER Id
Returns a device with specified ID.
.PARAMETER Include
Sets the criteria for the search.
.PARAMETER MaxResults
Set the max number of results (default is 50 and max is 10k).
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.OUTPUTS
CbcAlert[]
.NOTES
.EXAMPLE
PS > Get-CbcAlert

Returns all alerts

If you have multiple connections and you want alerts from a specific server
you can add the `-Server` param.

PS > Get-CbcAlert -Server $SpecifiedServer
.EXAMPLE
PS > Get-CBCAlert -Id "11a1a1a1-b22b-3333-44cc-dd5555d5d55d"

Returns the alert with specified id.

If you have multiple connections and you want alerts from a specific server
you can add the `-Server` param.

PS > Get-CBCAlert -Id "11a1a1a1-b22b-3333-44cc-dd5555d5d55d" -Server $SpecifiedServer
.EXAMPLE

The criteria for
$criteria = @{
    "category" = ["<string>", "<string>"],
    "create_time" = @{
        "end" = "<dateTime>",
        "range" = "<string>",
        "start" = "<dateTime>"
    },
    "device_id" = ["<long>", "<long>"],
    "device_name" = ["<string>", "<string>"],
    "device_os" = ["<string>", "<string>"],
    "device_os_version" = ["<string>", "<string>"],
    "device_username" = ["<string>", "<string>"],
    "first_event_time" = @{
        "end" = "<dateTime>",
        "range" = "<string>",
        "start" = "<dateTime>"
    },
    "group_results" = "<boolean>",
    "id" = ["<string>", "<string>"],
    "last_event_time" = @{
        "end" = "<dateTime>",
        "range" = "<string>",
        "start" = "<dateTime>"
    },
    "legacy_alert_id" = ["<string>", "<string>"],
    "minimum_severity" = "<integer>",
    "policy_id" = ["<long>", "<long>"],
    "policy_name" = ["<string>", "<string>"],
    "process_name" = ["<string>", "<string>"],
    "process_sha256" = ["<string>", "<string>"],
    "reputation" = ["<string>", "<string>"],
    "tag" = ["<string>", "<string>"],
    "target_value" = ["<string>", "<string>"],
    "threat_id" = ["<string>", "<string>"],
    "type" = ["<string>", "<string>"],
    "last_update_time" = @{
        "end" = "<dateTime>",
        "range" = "<string>",
        "start" = "<dateTime>"
    },
    "workflow" = ["<string>", "<string>"],
}

PS > Get-CBCAlert -Include $Criteria

Returns all alerts which correspond to the specified criteria.

If you have multiple connections and you want alerts from a specific server
you can add the `-Server` param.

PS > Get-CbcAlert -Include $Criteria -Server $SpecifiedServer
.EXAMPLE
PS > Get-CbcAlert -Id "1" | where { Set-CbcDevice -Id $_.DeviceID -QuarantineEnabled $true }

Quarantines a Device based on the alert
.EXAMPLE
PS > Get-CbcAlert -Include $Criteria | where { Set-CbcDevice -Id $_.DeviceID -QuarantineEnabled $true }

Quarantines a Device based on the alert
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/alerts-api/
#>

function Get-CbcAlert {
	[CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcAlert[]])]
	param(
		[Parameter(ParameterSetName = "Id",Position = 0)]
		[array]$Id,

		[Parameter(ParameterSetName = "Default")]
		[hashtable]$Include,

		[Parameter(ParameterSetName = "Default")]
		[int]$MaxResults = 50,

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "Default")]
		[CbcServer[]]$Servers
	)

	process {

		if ($Servers) {
			$ExecuteServers = $Servers
		} else {
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
					$RequestBody.rows = $MaxResults

                    $RequestBody = $RequestBody | ConvertTo-Json

					$Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Alerts"]["Search"] `
 						-Method POST `
 						-Server $_ `
 						-Body $RequestBody

                    $JsonContent = $Response.Content | ConvertFrom-Json

                    $JsonContent.results | ForEach-Object {
                        return Initialize-CbcAlert $_ $CurrentServer
                    }
                }
			}
			"Id" {
				$ExecuteServers | ForEach-Object {
					$Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Alerts"]["SpecificAlert"] `
 						-Method GET `
 						-Server $_ `
 						-Params @($Id)
					$JsonContent = $Response.Content | ConvertFrom-Json
					return Initialize-CbcAlert $JsonContent $_
				}
			}
		}
	}
}
