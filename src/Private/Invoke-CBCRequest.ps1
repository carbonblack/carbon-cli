using module ../PSCarbonBlackCloud.Classes.psm1
function Invoke-CBCRequest {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[CBCServer]$CBCServer,

		[Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[string]$Endpoint,

		[Parameter(Mandatory = $true,Position = 2)]
		[string]$Method,

		[array]$Params,

		[System.Object]$Body
	)

	begin {
		Write-Verbose "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {
		$Headers = @{
			"X-AUTH-TOKEN" = $CBCServer.Token
			"Content-Type" = "application/json"
			"User-Agent" = "PSCarbonBlackCloud"
		}

		$Params =,$CBCServer.Org + $Params
		$FormattedUri = $Endpoint -f $Params

		$FullUri = $CBCServer.Uri + $FormattedUri
		Write-Debug "[$($MyInvocation.MyCommand.Name)] Requesting ${FullUri}"
		try {
			return Invoke-WebRequest -Uri $FullUri -Headers $Headers -Method $Method -Body $Body
		}
		catch {
			$StatusCode = $_.Exception.Response.StatusCode
			Write-Error "Request to ${FullUri} failed. Status Code: ${StatusCode}"
		}
		return $null
	}

	end {
		Write-Verbose "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
