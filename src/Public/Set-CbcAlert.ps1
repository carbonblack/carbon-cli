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
		$ids = $Alert | ForEach-Object {
			$_.Id
		}
		if ($Include) {
			$RequestBody.criteria = $Include
			$Alert = Get-CbcAlert -Include $Include
		}
		else {
			$RequestBody.criteria = @{"id" = @($ids) }
		}

		if ($Alert.Count -gt 0) {
			$RequestBody = $RequestBody | ConvertTo-Json
			$ExecuteServers | ForEach-Object {
				$Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Alerts"]["Dismiss"] `
					-Method POST `
					-Server $_ `
					-Body $RequestBody

				$Response.Content | ConvertFrom-Json
				Write-Debug -Message "Result from dismiss alert: $($Response.Content)."
				return $Alert
			}
		}
		else {
			return @()
		}
		
	}

	end {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
