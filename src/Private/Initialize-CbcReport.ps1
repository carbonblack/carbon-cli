function Initialize-CbcReport {
    param(
        [Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$Response,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[string]$FeedId,

        [Parameter(Mandatory = $true,Position = 2)]
		[ValidateNotNullOrEmpty()]
		[CbcServer]$Server
	)
    [CbcReport]::new(
        $Response.id,
        $Response.title,
        $Response.description,
        $Response.severity,
        $Response.link,
        $Response.iocs_v2,
        $Response.visibility,
        $FeedId,
        $Server
    )
}
