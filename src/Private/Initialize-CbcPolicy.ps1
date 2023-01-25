using module ../PSCarbonBlackCloud.Classes.psm1

function Initialize-CbcPolicy {
    param(
		[Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$Response,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[CbcServer]$Server
	)
    [CbcPolicy]::new(
        $Response.id,
        $Response.name,
        $Response.description,
        $Response.priority_level,
        $Response.num_devices,
        $Response.position,
        $Response.is_system,
        $Server
    )
}
