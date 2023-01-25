using module ../PSCarbonBlackCloud.Classes.psm1

function Initialize-CbcDevice {
    param(
		[Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$Response,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[CbcServer]$Server
	)
    [CbcDevice]::new(
        $Response.id,
        $Response.status,
        $Response.group,
        $Response.policy_name,
        $Response.target_priority,
        $Response.email,
        $Response.name,
        $Response.os,
        $Response.last_contact_time,
        $Response.sensor_kit_type,
        $Server,
        $Response.deployment_type,
        $Response.last_device_policy_changed_time,
        $Response.last_device_policy_requested_time,
        $Response.last_external_ip_address,
        $Response.last_internal_ip_address,
        $Response.last_location,
        $Response.last_policy_updated_time,
        $Response.last_reported_time,
        $Response.last_reset_time,
        $Response.last_shutdown_time,
        $Response.mac_address,
        $Response.organization_id,
        $Response.organization_name,
        $Response.os_version,
        $Response.passive_mode,
        $Response.policy_id,
        $Response.policy_name,
        $Response.policy_override,
        $Response.quarantined,
        $Response.sensor_out_of_date,
        $Response.sensor_pending_update,
        $Response.sensor_version,
        $Response.deregistered_time,
        $Response.device_owner_id,
        $Response.registered_time,
        $Response.av_engine,
        $Response.av_last_scan_time,
        $Response.av_status,
        $Response.vulnerability_score,
        $Response.vulnerability_severity,
        $Response.host_based_firewall_reasons,
        $Response.host_based_firewall_status,
        $Response.sensor_gateway_url,
        $Response.sensor_gateway_uuid
    )
}
