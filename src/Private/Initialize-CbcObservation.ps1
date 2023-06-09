using module ../PSCarbonBlackCloud.Classes.psm1

function Initialize-CbcObservation {
    param(
		[Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$Response,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[CbcServer]$Server
	)
    [CbcObservation]::new(
        # TODO - add more fields
        $Response.alert_category,
        $Response.alert_id,
        $Response.observation_id,
        $Server
    )
}
