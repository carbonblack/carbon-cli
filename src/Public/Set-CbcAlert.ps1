using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet is used to do actions on alerts - currentlyonly dismiss is available.
.SYNOPSIS
This cmdlet is used to do actions on alerts - currentlyonly dismiss is available.
.PARAMETER Alert
An array of CbcAlert object types.
.PARAMETER Dismiss
To dismiss an alert.
.PARAMETER Id
The Id of specific alert to be dismissed.
.OUTPUTS
CbcAlert[]
.EXAMPLE
# This is going to execute Set-CbcAlert for all the alerts at once
PS > Set-CbcAlert -Alert (Get-CbcAlert -Include @{"device_id"= @("123"); "type"= @("CB_ANALYTICS")}) -Dismiss $true

# This is going to execute Set-CbcAlert per CbcAlert
PS > Get-CbcAlert -Include @{"device_id"= @("123"); "type"= @("CB_ANALYTICS")} | Set-CbcAlert -Dismiss $true

.EXAMPLE
PS > Set-CbcAlert -Id "07e1c1e9-d73f-18c7-c511-b9e83e482d89" -Dismiss $true

If you have multiple connections and you want devices from a specific connection
you can add the `-Server` param.
PS > Set-CbcAlert -Id "07e1c1e9-d73f-18c7-c511-b9e83e482d89" -Dismiss $true -Server $SpecificServer

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

		[ValidateNotNullOrEmpty()]
		[bool]$Dismiss,

		[Parameter(ValueFromPipeline = $true,
			Mandatory = $true,
			Position = 0,
			ParameterSetName = "Id")]
		[string]$Id,

		[Parameter(ParameterSetName = "Id")]
		[CbcServer[]]$Server
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
			"Id" {
				$ids = @($Id)
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
						return Get-CbcAlert -Include @{"id" = @($ids) } -Server $_
					}
				}
			}
			"Alert" {
				$AlertGroups = $Alert | Group-Object -Property Server
				foreach ($Group in $AlertGroups) {
					$RequestBody = @{
						"state"             = "DISMISSED"
						"comment"           = "Dismiss by CarbonCli"
						"remediation_state" = "FIXED"
					}
					$RequestBody.criteria = @{}
					$RequestBody.criteria.id = @()
					foreach ($CurrAlert in $Group.Group) {
						$RequestBody.criteria.id += $CurrAlert.Id
						$CurrentServer = $CurrAlert.Server
					}
					$JsonBody = $RequestBody | ConvertTo-Json
					$Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Alerts"]["Dismiss"] `
						-Method POST `
						-Server $CurrentServer `
						-Body $JsonBody
					if ($Response.StatusCode -ne 200) {
						Write-Error -Message $("Cannot complete action dismiss alert for alerts $($RequestBody.device_id) for $($Current)")
					}
					else {
						return Get-CbcAlert -Include @{"id" = @($RequestBody.criteria.id) } -Server $CurrentServer
					}
				}
			}
		}
	}
	end {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
