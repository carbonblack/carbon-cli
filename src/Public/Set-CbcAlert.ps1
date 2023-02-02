using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet is used to dismiss an alert.
.SYNOPSIS
This cmdlet is used to dismiss an alert.
.PARAMETER Alert
An array of CbcAlert object types.
.PARAMETER Dismiss
To dismiss an alert.
.OUTPUTS

.EXAMPLE
PS > Set-CbcAlert -Alert $alert -Dismiss

.EXAMPLE
PS > Set-CbcAlert -Id "ID" -Dismiss

.EXAMPLE
$Criteria = @{
	"category": ["<string>", "<string>"],
	"create_time": {
		"end": "<dateTime>",
		"range": "<string>",
		"start": "<dateTime>"
	},
	"device_id": ["<long>", "<long>"],
	"device_name": ["<string>", "<string>"],
	"device_os": ["<string>", "<string>"],
	"device_os_version": ["<string>", "<string>"],
	"device_username": ["<string>", "<string>"],
	"group_results": "<boolean>",
	"id": ["<string>", "<string>"],
	"legacy_alert_id": ["<string>", "<string>"],
	"minimum_severity": "<integer>",
	"policy_id": ["<long>", "<long>"],
	"policy_name": ["<string>", "<string>"],
	"process_name": ["<string>", "<string>"],
	"process_sha256": ["<string>", "<string>"],
	"report_id": ["<string>", "<string>"],
	"report_name": ["<string>", "<string>"],
	"reputation": ["<string>", "<string>"],
	"tag": ["<string>", "<string>"],
	"target_value": ["<string>", "<string>"],
	"threat_id": ["<string>", "<string>"],
	"type": ["<string>", "<string>"],
	"watchlist_id": ["<string>", "<string>"],
	"watchlist_name": ["<string>", "<string>"],
	"workflow": ["<string>", "<string>"],
}
PS > Set-CbcAlert -Include $Criteria -Dismiss
PS > Set-CbcAlert -Include @{"id": @("123", "124")} -Dismiss

If you have multiple connections and you want devices from a specific server
you can add the `-Server` param.

.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/alerts-api#bulk-create-workflows
#>

function Set-CbcAlert {
	[CmdletBinding(DefaultParameterSetName = "default")]
	param(
		[Parameter(ValueFromPipeline = $true,
			Mandatory = $true,
			Position = 0,
			ParameterSetName = "Alert")]
		[CbcAlert[]]$Alert,

		[Parameter(ParameterSetName = "Default")]
		[hashtable]$Include,

		[Parameter(ValueFromPipeline = $true,
			Mandatory = $true,
			Position = 0,
			ParameterSetName = "Id")]
		[string]$Id,

		[Parameter(ParameterSetName = "Id")]
		[Parameter(ParameterSetName = "Default")]
		[CbcServer[]]$Servers,

		[ValidateNotNullOrEmpty()]
		[bool]$Dismiss
	)

	begin {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {
		switch ($PSCmdlet.ParameterSetName) {
			"Id" {
				$Alert = Get-CbcAlert -Id $Id
			}
		}

		if ($Servers) {
			$ExecuteServers = $Servers
		}
		else {
			$ExecuteServers = $global:CBC_CONFIG.currentConnections
		}

		$RequestBody = @{
			"state"             = "DISMISSED";
			"comment"           = "Dismiss by CarbonCli";
			"remediation_state" = "FIXED" 
		}
		
		if ($Include) {
			$RequestBody.criteria = $Include
			$Alert = Get-CbcAlert -Include $Include
		}
		else {
			$ids = $Alert | ForEach-Object {
				$_.Id
			}
			$RequestBody.criteria = @{"id" = @($ids) }
		}
		$JsonBody = $RequestBody | ConvertTo-Json
		$ExecuteServers | ForEach-Object {
			$Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Alerts"]["Dismiss"] `
				-Method POST `
				-Server $_ `
				-Body $JsonBody
			if ($Response.StatusCode -ne 200) {
				Write-Error -Message $("Cannot complete action dismiss alert for alerts $($RequestBody.device_id) for $($_)")
			}
			else {
				return $Alert
			}	
		}
	}
	end {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
