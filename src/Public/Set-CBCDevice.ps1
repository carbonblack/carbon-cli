using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet is used to update, configure and set the state of a device.

.PARAMETER Quarantine
If present the specified device is quarantined.
.PARAMETER Unquarantine
If present the specified device is unquarantined.
.PARAMETER UpdatePolicy
If present the specified device's policy is updated with specified policy Id.
.PARAMETER UpdateSensor
If present the specified device's sensor version is updated with the specified sensor version.
.PARAMETER UninstallSensor
If present the specified device's sensor is uninstalled.
.PARAMETER Device
An array of Device objects. Can be passed through the pipeline and used with the Set-CBCDevice options.
.PARAMETER Alert
An array of Alert objects. Can be passed through the pipeline and used with the Set-CBCDevice options(Quarantine, Unquarantine and UpdatePolicy only).


.OUTPUTS
Response code.
.NOTES
-------------------------- Example 1 --------------------------
Get-CBCDevice -Id "1234" | Set-CBCDevice -Quarantine
Quarantines the device with specified Id.

-------------------------- Example 2 --------------------------
Get-CBCDevice -Id "1234" | Set-CBCDevice -Unquarantine
Unquarantines the device with specified Id.

-------------------------- Example 3 --------------------------
Get-CBCDevice -Id "1234" | Set-CBCDevice -UpdatePolicy -PolicyId "5678"
Updates the policy of the device with the specified policy id.

-------------------------- Example 4 --------------------------
Get-CBCDevice -Id "1234" | Set-CBCDevice -UpdateSensor -SensorVersion "1.0.0.0"
Updates the Sensor version of the device with the specified one.

-------------------------- Example 5 --------------------------
Get-CBCDevice -Id "1234" | Set-CBCDevice -UninstallSensor
Uninstalles the sensor on the specified device.

-------------------------- Example 6 --------------------------
Get-CBCAlert -Id "1234" | Set-CBCDevice -Quarantine
Quarantines the device from the returned alert.

-------------------------- Example 7 --------------------------
Get-CBCAlert -Id "1234" | Set-CBCDevice -Unquarantine
Unquarantines the device from the returned alert.

-------------------------- Example 8 --------------------------
Get-CBCAlert -Id "1234" | Set-CBCDevice -UpdatePolicy -PolicyId "5678"
Updates the policy of the device from the returned alert with the specified policy id.

.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/devices-api/
#>

function Set-CBCDevice {
  param(
    [Parameter(ParameterSetName = "Quarantine")]
    [switch]$Quarantine,

    [Parameter(ParameterSetName = "Unquarantine")]
    [switch]$Unquarantine,

    [Parameter(ParameterSetName = "UpdatePolicy")]
    [switch]$UpdatePolicy,

    [Parameter(ParameterSetName = "UpdateSensor")]
    [switch]$UpdateSensor,

    [Parameter(ParameterSetName = "UninstallSensor")]
    [switch]$UninstallSensor,

    [Parameter(ValueFromPipeline = $true)]
    [Device[]]$Device,

    [Parameter(ValueFromPipeline = $true)]
    $Alert,

    [Parameter(ParameterSetName = "UpdateSensor",Mandatory = $true)]
    [string]$SensorVersion
  )

  process {
    switch ($PSCmdlet.ParameterSetName) {
      "Quarantine" {
        if ($Device) {
          foreach ($device in $Device) {
            $Body = @{}
            $Body["action_type"] = "QUARANTINE"
            $Body["device_id"] = @($device.Id)
            $Body["options"] = @{
              "toggle" = "ON"
            }
            $jsonBody = ConvertTo-Json -InputObject $Body
            if ($null -ne $device.CBCServer) {
              $Response = Invoke-CBCRequest -CBCServer $device.CBCServer `
                 -Endpoint $CBC_CONFIG.endpoints["Devices"]["Quarantine"] `
                 -Method POST `
                 -Body $jsonBody
              $Response
            }

          }
        }
        elseif ($Alert) {
          foreach ($alert in $Alert) {
            $Body = @{}
            $Body["action_type"] = "QUARANTINE"
            $Body["device_id"] = @($alert.DeviceId)
            $Body["options"] = @{
              "toggle" = "ON"
            }
            $jsonBody = ConvertTo-Json -InputObject $Body
            if ($null -ne $alert.CBCServer) {
              $Response = Invoke-CBCRequest -CBCServer $alert.CBCServer `
                 -Endpoint $CBC_CONFIG.endpoints["Devices"]["Quarantine"] `
                 -Method POST `
                 -Body $jsonBody
              $Response
            }

          }
        }
      }
      "Unquarantine" {
        if ($Device) {
          foreach ($device in $Device) {
            $Body = @{}
            $Body["action_type"] = "QUARANTINE"
            $Body["device_id"] = @($device.Id)
            $Body["options"] = @{
              "toggle" = "OFF"
            }
            $jsonBody = ConvertTo-Json -InputObject $Body
            if ($null -ne $device.CBCServer) {
              $Response = Invoke-CBCRequest -CBCServer $device.CBCServer `
                 -Endpoint $CBC_CONFIG.endpoints["Devices"]["Quarantine"] `
                 -Method POST `
                 -Body $jsonBody
              $Response
            }
          }
        }
        elseif ($Alert) {
          foreach ($alert in $Alert) {
            $Body = @{}
            $Body["action_type"] = "QUARANTINE"
            $Body["device_id"] = @($alert.DeviceId)
            $Body["options"] = @{
              "toggle" = "OFF"
            }
            $jsonBody = ConvertTo-Json -InputObject $Body
            if ($null -ne $alert.CBCServer) {
              $Response = Invoke-CBCRequest -CBCServer $alert.CBCServer `
                 -Endpoint $CBC_CONFIG.endpoints["Devices"]["Quarantine"] `
                 -Method POST `
                 -Body $jsonBody
              $Response
            }

          }
        }
      }
      "UpdatePolicy" {
        if ($Device) {
          foreach ($device in $Device) {
            $Body = @{}
            $Body["action_type"] = "UPDATE_POLICY"
            $Body["device_id"] = @($device.Id)
            $Body["options"] = @{
              "policy_id" = $PolicyId
            }
            $jsonBody = ConvertTo-Json -InputObject $Body
            if ($null -ne $device.CBCServer) {
              $Response = Invoke-CBCRequest -CBCServer $device.CBCServer `
                 -Endpoint $CBC_CONFIG.endpoints["Devices"]["UpdatePolicy"] `
                 -Method POST `
                 -Body $jsonBody
              $Response
            }
          }
        }
        elseif ($Alert) {
          foreach ($alert in $Alert) {
            $Body = @{}
            $Body["action_type"] = "UPDATE_POLICY"
            $Body["device_id"] = @($alert.DeviceId)
            $Body["options"] = @{
              "policy_id" = $PolicyId
            }
            $jsonBody = ConvertTo-Json -InputObject $Body
            if ($null -ne $alert.CBCServer) {
              $Response = Invoke-CBCRequest -CBCServer $alert.CBCServer `
                 -Endpoint $CBC_CONFIG.endpoints["Devices"]["UpdatePolicy"] `
                 -Method POST `
                 -Body $jsonBody
              $Response
            }
          }
        }
      }
      "UpdateSensor" {
        if ($Device) {
          foreach ($device in $Device) {
            $Body = @{}
            $Body["action_type"] = "UPDATE_SENSOR_VERSION"
            $Body["device_id"] = @($device.Id)
            $Body["options"] = @{
              "sensor_version" = @{
                $device.Os = $SensorVersion
              }
            }
            $jsonBody = ConvertTo-Json -InputObject $Body
            if ($null -ne $device.CBCServer) {
              $Response = Invoke-CBCRequest -CBCServer $device.CBCServer `
                 -Endpoint $CBC_CONFIG.endpoints["Devices"]["UpdateSensor"] `
                 -Method POST `
                 -Body $jsonBody

              $Response
            }
          }
        }
        elseif ($Alert) {
          foreach ($alert in $Alert) {
            $Body = @{}
            $Body["action_type"] = "UPDATE_SENSOR_VERSION"
            $Body["device_id"] = @($alert.DeviceId)
            $Body["options"] = @{
              "sensor_version" = @{
                $alert.DeviceOs = $SensorVersion
              }
            }
            $jsonBody = ConvertTo-Json -InputObject $Body
            if ($null -ne $alert.CBCServer) {
              $Response = Invoke-CBCRequest -CBCServer $alert.CBCServer `
                 -Endpoint $CBC_CONFIG.endpoints["Devices"]["UpdateSensor"] `
                 -Method POST `
                 -Body $jsonBody
              $Response
            }
          }
        }
      }
      "UninstallSensor" {
        if ($Device) {
          foreach ($device in $Device) {
            $Body = @{}
            $Body["action_type"] = "UNINSTALL_SENSOR"
            $Body["device_id"] = @($device.Id)
            $jsonBody = ConvertTo-Json -InputObject $Body
            if ($null -ne $device.CBCServer) {
              $Response = Invoke-CBCRequest -CBCServer $device.CBCServer `
                 -Endpoint $CBC_CONFIG.endpoints["Devices"]["UninstallSensor"] `
                 -Method POST `
                 -Body $jsonBody

              $Response
            }
          }
        }
        elseif ($Alert) {
          foreach ($alert in $Alert) {
            $Body = @{}
            $Body["action_type"] = "UNINSTALL_SENSOR"
            $Body["device_id"] = @($alert.DeviceId)
            $jsonBody = ConvertTo-Json -InputObject $Body
            if ($null -ne $alert.CBCServer) {
              $Response = Invoke-CBCRequest -CBCServer $alert.CBCServer `
                 -Endpoint $CBC_CONFIG.endpoints["Devices"]["UninstallSensor"] `
                 -Method POST `
                 -Body $jsonBody
              $Response
            }
          }
        }
      }
    }
  }
}

