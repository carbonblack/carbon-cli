function Initialize-CbcJob {
    param(
		[Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[string]$JobId,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[string]$Type,

        [Parameter(Mandatory = $true,Position = 2)]
        [ValidateNotNullOrEmpty()]
		[string]$Status,

        [Parameter(Mandatory = $true,Position = 3)]
		[ValidateNotNullOrEmpty()]
		[CbcServer]$Server
	)
    [CbcJob]::new(
        $JobId,
        $Type,
        $Status,
        $Server
    )
}
