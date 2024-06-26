using module ../CarbonCLI.Classes.psm1

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
        $Response.sensor_gateway_uuid,
        $Response.current_sensor_policy_name,
        $Response.last_user_name,
        $Response.sensor_states,
        $Response.activation_code,
        $Response.appliance_name,
        $Response.appliance_uuid,
        $Response.base_device,
        $Response.cluster_name,
        $Response.compliance_status,
        $Response.datacenter_name,
        $Response.esx_host_name,
        $Response.esx_host_uuid,
        $Response.golden_device,
        $Response.golden_device_id,
        $Response.golden_device_status,
        $Response.nsx_enabled,
        $Response.vcenter_host_url,
        $Response.vcenter_name,
        $Response.vcenter_uuid,
        $Response.vdi_prodvider,
        $Response.virtual_machine,
        $Response.virtual_private_cloud_id,
        $Response.virtualization_provider,
        $Response.vm_ip,
        $Response.vm_name,
        $Response.vm_uuid,
        $Response.auto_scaling_group_name,
        $Response.cloud_provider_account_id,
        $Response.cloud_provider_resource_id,
        $Response.cloud_provider_tags,
        $Response.cloud_provider_resource_group,
        $Response.cloud_provider_scale_group,
        $Response.cloud_provider_network,
        $Response.cloud_provider_managed_identity,
        $Response.infrastructure_provider
    )
}
