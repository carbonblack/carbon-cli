function Initialize-CbcFeedDetails {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$Response,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[CbcServer]$Server,

        [Parameter(Mandatory = $false, Position = 2)]
		[System.Object[]]$Reports
	)
    [CbcFeedDetails]::new(
        $Response.id,
        $Response.name,
        $Response.owner,
        $Response.provider_url,
        $Response.summary,
        $Response.category,
        $Response.alertable,
        $Response.access,
        $Reports,
        $Server
    )
}
