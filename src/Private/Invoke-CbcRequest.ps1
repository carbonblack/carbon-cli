using module ../PSCarbonBlackCloud.Classes.psm1
function Invoke-CBCRequest {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[CbcServer]$Server,

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

		$Params =,$Server.Org + $Params
		$FormattedUri = $Endpoint -f $Params

		$FullUri = $Server.Uri + $FormattedUri
		Write-Debug "[$($MyInvocation.MyCommand.Name)] requesting: ${FullUri}"
		Write-Debug "[$($MyInvocation.MyCommand.Name)] with request body: ${Body}"
		Write-Debug "[$($MyInvocation.MyCommand.Name)] with method body: ${Method}"
		Write-Debug "[$($MyInvocation.MyCommand.Name)] with uri params body: ${Params}"
		try {
			$Request = Invoke-WebRequest -Uri $FullUri -Headers $Headers -Method $Method -Body $Body
			Write-Debug "[$($MyInvocation.MyCommand.Name)] got response with content: ${Request.Content}"
			Write-Debug "[$($MyInvocation.MyCommand.Name)] got status code: ${Request.StatusCode}"
			return $Request
		}
		catch {
			Write-Debug $_.Exception
			$StatusCode = $_.Exception.Response.StatusCode
			Write-Error "[$($MyInvocation.MyCommand.Name)] request to ${FullUri} failed. Status Code: ${StatusCode}"
			if ($_.Exception.Response.StatusCode -eq 404) {
				return @{"Content" = ""} 
			}
			throw $_.Exception
		}
		return $null
	}

	end {
		Write-Verbose "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
