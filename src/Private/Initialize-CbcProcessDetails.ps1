using module ../PSCarbonBlackCloud.Classes.psm1

function Initialize-CbcProcessDetails {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Response,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [CbcServer]$Server
    )
    [CbcProcessDetails]::new(
        $Response.alert_category,
        $Response.alert_id,
        $Response.backend_timestamp,
        $Response.blocked_hash,
        $Response.device_external_ip,
        $Response.device_id,
        $Response.device_internal_ip,
        $Response.device_os,
        $Response.device_policy,
        $Response.device_policy_id,
        $Response.event_type,
        $Response.parent_cmdline,
        $Response.parent_guid,
        $Response.process_cmdline,
        $Response.process_guid,
        $Response.process_hash,
        $Server
    )
}
