using module ../CarbonCLI.Classes.psm1

function Update-CbcWatchlist {
    param(
        [Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[CbcWatchlist]$WatchlistObj,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[hashtable]$PSBoundParameters
	)
    $RequestBody = @{}
    $RequestBody.name = $WatchlistObj.Name
    $RequestBody.description = $WatchlistObj.Description
    $RequestBody.id = $WatchlistObj.Id
    $RequestBody.tags_enabled = $WatchlistObj.TagsEnabled
    $RequestBody.alerts_enabled = $WatchlistObj.AlertsEnabled
    $RequestBody.alert_classification_enabled = $WatchlistObj.AlertClassificationEnabled
    $RequestBody.classifier = @{
        "key" = "feed_id"
        "value" = $WatchlistObj.FeedId
    }
    
    if ($PSBoundParameters.ContainsKey("Name")) {
        $RequestBody.name = $PSBoundParameters["Name"]
    }
    if ($PSBoundParameters.ContainsKey("Description")) {
        $RequestBody.description = $PSBoundParameters["Description"]
    }
    if ($PSBoundParameters.ContainsKey("AlertsEnabled")) {
        $RequestBody.alerts_enabled = $PSBoundParameters["AlertsEnabled"]
    }
    if ($PSBoundParameters.ContainsKey("TagsEnabled")) {
        $RequestBody.tags_enabled = $PSBoundParameters["TagsEnabled"]
    }
    if ($PSBoundParameters.ContainsKey("AlertClassificationEnabled")) {
        $RequestBody.alert_classification_enabled = $PSBoundParameters["AlertClassificationEnabled"]
    }

    $RequestBody = $RequestBody | ConvertTo-Json
    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Watchlist"]["Details"] `
        -Method PUT `
        -Server $WatchlistObj.Server `
        -Params $WatchlistObj.Id `
        -Body $RequestBody

    if ($Response.StatusCode -ne 200) {
        Write-Error -Message $("Cannot update watchlist(s) for $($WatchlistObj.Server)")
    }
    else {
        Write-Debug -Message $("Watchlist update $($WatchlistObj.Server)")
        $JsonContent = $Response.Content | ConvertFrom-Json
        return Initialize-CbcWatchlist $JsonContent $WatchlistObj.Server $JsonContent.classifier.value
    }
}