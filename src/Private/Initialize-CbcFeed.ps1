function Initialize-CbcFeed {
    param(
        [Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$Response,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[CbcServer]$Server
	)
    [CbcFeed]::new(
        $Response.id,
        $Response.name,
        $Response.owner,
        $Response.provider_url,
        $Response.summary,
        $Response.category,
        $Response.alertable,
        $Response.reports,
        $Server
    )
}
