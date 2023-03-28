using module ../PSCarbonBlackCloud.Classes.psm1
function Invoke-PagedCbcRequest {
	[CmdletBinding()]
	#[OutputType([BasicHtmlWebResponseObject[]])]
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

		[hashtable]$Body,

		#The limit of the API Server request
		[int]$ApiResultLimit = 10000,

		#The client side max results request
		[int]$MaxResults = 50,

		[int]$StartIterator = 0 

	)

	begin {
		Write-Verbose "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {
		
		if ($null -eq $Body.sort) {
			Write-Debug " There is no sorting criteria defined in the request body. Results might not be complete"
		}
		
		$TotalResultCount = 0
		$Body.rows = $ApiResultLimit
		
		
		Do {
			<#
			Test for a corner case where we've reached the desired count of objects,
			but the returned results in the last iteration was -eq to the $ApiResultLimit
			Would happen when $MaxResults % $ApiResultLimit -eq 0
			#>
			if ($MaxResults -eq $TotalResultCount) {
				return
			}
			#Test if remaining to retrieve are less than what we can retrieve with one api call
			if ($MaxResults - $TotalResultCount -lt $ApiResultLimit) {
				
				#If true, retrieve remaining only 
				$Body.rows = $MaxResults - $TotalResultCount
				
			}
			$Body.start = $StartIterator
			$convertedBody = $Body | ConvertTo-Json
			$Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Alerts"]["Search"] `
				-Method $Method `
				-Server $Server `
				-Body $convertedBody

			$JsonContent = $Response.Content | ConvertFrom-Json
			
			#JsonContent.results.count is the count of the returned objects
			Write-Debug "JsonContent.results.count is: $($JsonContent.results.count)"
			Write-Debug "TotalResultCount is $TotalResultCount"
			$TotalResultCount += $JsonContent.results.count
			$StartIterator += $JsonContent.results.count

			#Returning the response without exiting the loop, no return statement
			$Response

		} While (-Not ($JsonContent.results.count -lt $ApiResultLimit) )
	}

	end {
		Write-Verbose "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
