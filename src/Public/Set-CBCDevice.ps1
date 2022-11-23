using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet is used to update, configure and set the state of a device.

.PARAMETER Quarantine
If present the specified device is quarantined.
.PARAMETER Unquarantine
If present the specified device is unquarantined.
.PARAMETER UpdatePolicy
If present the specified device's policy is updated with some policy Id.
.PARAMETER Device
An array of Device objects. Can be passed through the pipeline.
.PARAMETER DeviceId
An array of Device Ids.
.PARAMETER PolicyId
A PolicyId is used when you want to update a device's policy.
.PARAMETER OS
Sets a specified server to execute the cmdlet with.
.PARAMETER Server 
Sets a specified server to execute the cmdlet with.

.OUTPUTS

.NOTES
-------------------------- Example 1 --------------------------
Set-CBCDevice -Quarantine -DeviceId "1234"
Quarantines the device with specified Id.

-------------------------- Example 2 --------------------------
Get-CBCDevice -Id "1234" | Set-CBCDevice -Quarantine
This example does the same thing as in 'Example 1'.

-------------------------- Example 3 --------------------------
Set-CBCDevice -Unquarantine -DevicId "1234"
Unquarantines the device with specified Id.

-------------------------- Example 4 --------------------------
Get-CBCDevice -Id "1234" | Set-CBCDevice -Unquarantine
This example does the same thing as in 'Example 3'.

-------------------------- Example 5 --------------------------
Set-CBCDevice -UpdatePolicy -DeviceId "1234" -PolicyId "5678"
Updates the policy of the device with the specified policy id.

-------------------------- Example 6 --------------------------
Get-CBCDevice -Id "1234" | Set-CBCDevice -UpdatePolicy -PolicyId "5678"
This example does the same thing as in 'Example 5'.

-------------------------- Example 7 --------------------------
Set-CBCDevice -UpdateSensor -DeviceId "1234" -OS "SomeOS" -SensorVersion "1.0.0.0"
Updates the Sensor version of the device.
.LINK

Online Version: http://devnetworketc/
#>

function Set-CBCDevice {
    Param(
        [switch]$Quarantine,

        [switch]$Unquarantine,

        [switch]$UpdatePolicy,

        [switch]$UpdateSensor,

        [Parameter(ValueFromPipeline = $true)]
        [Device[]]$Device,

        [string[]] $DeviceId,

        [string]$PolicyId,

        [string]$OS,

        [string]$SensorVersion,

        [PSCustomObject] $Server        
    )

    Process {
        $ExecuteTo = $CBC_CONFIG.currentConnections
        if ($Server) {
            $ExecuteTo = @($Server)
        }
        if ($Quarantine) {
            $Body = @{}
            $Body["action_type"] = "QUARANTINE"
            if ($Device) {
                $DeviceIds = @()
                foreach ($device in $Device) {
                    $DeviceIds += $device.Id
                }
                $Body["device_id"] = $DeviceIds
            }
            else {
                $Body["device_id"] = $DeviceId
            }
            $Body["options"] = @{
                "toggle" = "ON"
            }
            $jsonBody = ConvertTo-Json -InputObject $Body
            $ExecuteTo | ForEach-Object {
                $Response = Invoke-CBCRequest -Server $_ `
                    -Endpoint $CBC_CONFIG.endpoints["Devices"]["Quarantine"] `
                    -Method POST `
                    -Body $jsonBody
            }
            return $Response
        }
        
    
        if ($Unquarantine) {
            $Body = @{}
            $Body["action_type"] = "QUARANTINE"
            if ($Device) {
                $DeviceIds = @()
                foreach ($device in $Device) {
                    $DeviceIds += $device.Id
                }
                $Body["device_id"] = $DeviceIds
            }
            else {
                $Body["device_id"] = $DeviceId
            }
            $Body["options"] = @{
                "toggle" = "OFF"
            }
        
            $jsonBody = ConvertTo-Json -InputObject $Body
            $ExecuteTo | ForEach-Object {
                $Response = Invoke-CBCRequest -Server $_ `
                    -Endpoint $CBC_CONFIG.endpoints["Devices"]["Quarantine"] `
                    -Method POST `
                    -Body $jsonBody

            }
            return $Response
        }
        if ($UpdatePolicy) {
            $Body = @{}
            $Body["action_type"] = "UPDATE_POLICY"
            if ($Device) {
                $DeviceIds = @()
                foreach ($device in $Device) {
                    $DeviceIds += $device.Id
                }
                $Body["device_id"] = $DeviceIds
            }
            else {
                $Body["device_id"] = $DeviceId
            }
            $Body["options"] = @{
                "policy_id" = $PolicyId
            }

            $jsonBody = ConvertTo-Json -InputObject $Body
            $ExecuteTo | ForEach-Object {
                $Response = Invoke-CBCRequest -Server $_ `
                    -Endpoint $CBC_CONFIG.endpoints["Devices"]["UpdatePolicy"] `
                    -Method POST `
                    -Body $jsonBody
            }
            return $Response
        }

        if ($UpdateSensor) {
            $osArr = @("XP", "WINDOWS", "MAC", "AV_SIG", "OTHER", "RHEL", "UBUNTU", "SUSE", "AMAZON_LINUX", "MAC_OSX")
            $Body = @{}
            $Body["action_type"] = "UPDATE_SENSOR_VERSION"
            if ($Device) {
                $DeviceIds = @()
                foreach ($device in $Device) {
                    $DeviceIds += $device.Id
                }
                $Body["device_id"] = $DeviceIds
            }
            else {
                $Body["device_id"] = $DeviceId
            }
            if ($osArr.Contains($OS)) {
                $OS = $OS.ToUpper()
                $Body["options"] = @{
                    "sensor_version" = @{
                        $OS = $SensorVersion
                    }
                }
            }
            else {
                $Body["options"] = @{
                    "sensor_version" = @{
                        "OTHER" = $SensorVersion
                    }
                }
            }
            $jsonBody = ConvertTo-Json -InputObject $Body
            $ExecuteTo | ForEach-Object {
                $Response = Invoke-CBCRequest -Server $_ `
                    -Endpoint $CBC_CONFIG.endpoints["Devices"]["UpdateSensor"] `
                    -Method POST `
                    -Body $jsonBody
            }
            return $Response
        }
        
    }
}