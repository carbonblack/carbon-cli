using module ../CarbonCLI.Classes.psm1

function Initialize-CbcAlert {
    param(
		[Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$Response,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[CbcServer]$Server
	)
    [CbcAlert]::new(
        $Response.id,
        $Response.device_id,
        $Response.backend_timestamp,
        $Response.first_event_timestamp,
        $Response.last_event_timestamp,
        $Response.last_update_timestamp,
        $Response.device_policy_id,
        $Response.device_policy,
        $Response.severity,
        $Response.tags,
        $Response.device_target_value,
        $Response.threat_id,
        $Response.type,
        $Response.workflow,
        $Server
    )
}
