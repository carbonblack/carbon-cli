using module ../PSCarbonBlackCloud.Classes.psm1

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
        $Response.category,
        $Response.create_time,
        $Response.first_event_time,
        $Response.last_event_time,
        $Response.last_update_time,
        $Response.group_details,
        $Response.policy_id,
        $Response.policy_name,
        $Response.severity,
        $Response.tags,
        $Response.target_value,
        $Response.threat_id,
        $Response.type,
        $Response.workflow,
        $Server
    )
}
