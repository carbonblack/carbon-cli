using module ../PSCarbonBlackCloud.Classes.psm1

function Update-CbcReport {
    param(
        [Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[CbcReport]$ReportObj,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[hashtable]$PSBoundParameters
	)
    $RequestBody = @{}
    $RequestBody.id = $ReportObj.Id
    $RequestBody.title = $ReportObj.Title
    $RequestBody.description = $ReportObj.Description
    $RequestBody.severity = $ReportObj.Severity
    $RequestBody.link = $ReportObj.Link
    $RequestBody.visibility = $ReportObj.visibility
    $RequestBody.iocs_v2 = $ReportObj.IocsV2
    $RequestBody.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
    
    if ($PSBoundParameters.ContainsKey("Title")) {
        $RequestBody.title = $PSBoundParameters["Title"]
    }
    if ($PSBoundParameters.ContainsKey("Description")) {
        $RequestBody.description = $PSBoundParameters["Description"]
    }
    if ($PSBoundParameters.ContainsKey("Severity")) {
        $RequestBody.severity = $PSBoundParameters["Severity"]
    }

    $RequestBody = $RequestBody | ConvertTo-Json -Depth 100
    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
        -Method PUT `
        -Server $ReportObj.Server `
        -Params @($ReportObj.FeedId, $ReportObj.Id) `
        -Body $RequestBody

    if ($Response.StatusCode -ne 200) {
        Write-Error -Message $("Cannot update report(s) for $($ReportObj.Server)")
    }
    else {
        Write-Debug -Message $("Report update $($ReportObj.Server)")
        $JsonContent = $Response.Content | ConvertFrom-Json
        return Initialize-CbcReport $JsonContent $ReportObj.FeedId $ReportObj.Server
    }
}