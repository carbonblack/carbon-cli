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
PS > Set-CbcAlert -Alert $alert -Dismiss $true

# This is going to execute Set-CbcAlert for all the alerts one time
PS > Set-CbcAlert -Alert (Get-CbcAlert -Include @{"device_id"= @("123"); "type"= @("CB_ANALYTICS")}) -Dismiss $true

# This is going to execute Set-CbcAlert per Alert
PS > Get-CbcAlert -Include @{"device_id"= @("123"); "type"= @("CB_ANALYTICS")} | Set-CbcAlert -Dismiss $true

.EXAMPLE
PS > Set-CbcAlert -Id "ID" -Dismiss $true

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

		[Parameter(ValueFromPipeline = $true,
			Mandatory = $true,
			Position = 0,
			ParameterSetName = "Id")]
		[string]$Id,

		[Parameter(ParameterSetName = "Id")]
		[Parameter(ParameterSetName = "Default")]
		[CbcServer[]]$Server,

		[ValidateNotNullOrEmpty()]
		[bool]$Dismiss
	)

	begin {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {
		switch ($PSCmdlet.ParameterSetName) {
			"Id" {
				$ids = @($Id)
			}
			"Alert" {
				$ids = $Alert | ForEach-Object {
					$_.Id
				}
			}
		}

		if ($Server) {
			$ExecuteServers = $Server
		}
		else {
			$ExecuteServers = $global:CBC_CONFIG.currentConnections
		}

		$RequestBody = @{
			"state"             = "DISMISSED"
			"comment"           = "Dismiss by CarbonCli"
			"remediation_state" = "FIXED"
		}
		$RequestBody.criteria = @{"id" = @($ids) }

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
				return Get-CbcAlert -Include @{"id" = @($ids)} -Server $_
			}
		}
	}
	end {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
