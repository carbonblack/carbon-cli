function Initialize-CbcIoc {
    param(
        [Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$Response,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[string]$ReportId,

        [Parameter(Mandatory = $true,Position = 2)]
		[ValidateNotNullOrEmpty()]
		[CbcServer]$Server
	)
    [CbcIoc]::new(
        $Response.id,
        $Response.match_type,
        $Response.values,
        $Response.field,
        $Response.link,
        $ReportId,
        $Server
    )
}
