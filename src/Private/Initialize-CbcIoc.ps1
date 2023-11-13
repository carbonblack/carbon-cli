function Initialize-CbcIoc {
    param(
        [Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$Response,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[string]$FeedId,

        [Parameter(Mandatory = $true,Position = 2)]
		[ValidateNotNullOrEmpty()]
		[string]$ReportId,

        [Parameter(Mandatory = $true,Position = 3)]
		[ValidateNotNullOrEmpty()]
		[CbcServer]$Server
	)
    [CbcIoc]::new(
        $Response.id,
        $Response.match_type,
        $Response.values,
        $Response.field,
        $Response.link,
        $FeedId,
        $ReportId,
        $Server
    )
}
