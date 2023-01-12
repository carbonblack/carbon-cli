using module ../PSCarbonBlackCloud.Classes.psm1
function Invoke-CBCRequest {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[CBCServer]$Server,

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
			"X-AUTH-TOKEN" = $Server.Token
			"Content-Type" = "application/json"
			"User-Agent" = "PSCarbonBlackCloud"
		}

		$Params = ,$Server.Org + $Params
		$FormattedUri = $Endpoint -f $Params

		$FullUri = $Server.Uri + $FormattedUri
		Write-Debug "[$($MyInvocation.MyCommand.Name)] requesting: ${FullUri}"
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
