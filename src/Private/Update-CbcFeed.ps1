using module ../CarbonCLI.Classes.psm1

function Update-CbcFeed {
    param(
        [Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[CbcFeed]$FeedObj,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[hashtable]$PSBoundParameters
	)
    $RequestBody = @{}
    $RequestBody.name = $FeedObj.Name
    $RequestBody.summary = $FeedObj.Summary
    $RequestBody.access = $FeedObj.Access
    $RequestBody.category = $FeedObj.Category
    $RequestBody.alertable = $FeedObj.Alertable
    $RequestBody.provider_url = $FeedObj.ProviderUrl
    
    if ($PSBoundParameters.ContainsKey("Name")) {
        $RequestBody.name = $PSBoundParameters["Name"]
    }
    if ($PSBoundParameters.ContainsKey("Summary")) {
        $RequestBody.summary = $PSBoundParameters["Summary"]
    }
    if ($PSBoundParameters.ContainsKey("Category")) {
        $RequestBody.category = $PSBoundParameters["Category"]
    }
    if ($PSBoundParameters.ContainsKey("Alertable")) {
        $RequestBody.alertable = $PSBoundParameters["Alertable"]
    }
    if ($PSBoundParameters.ContainsKey("ProviderUrl")) {
        $RequestBody.provider_url = $PSBoundParameters["ProviderUrl"]
    }

    $RequestBody = $RequestBody | ConvertTo-Json
    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Feed"]["FeedInfo"] `
        -Method PUT `
        -Server $FeedObj.Server `
        -Params $FeedObj.Id `
        -Body $RequestBody

    if ($Response.StatusCode -ne 200) {
        Write-Error -Message $("Cannot update feed(s) for $($FeedObj.Server)")
    }
    else {
        Write-Debug -Message $("Feed update $($Feed.Server)")
        $JsonContent = $Response.Content | ConvertFrom-Json
        return Initialize-CbcFeed $JsonContent $FeedObj.Server
    }
}