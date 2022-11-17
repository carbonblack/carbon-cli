<#
.DESCRIPTION
This cmdlet is used to update, configure and set the state of a device.

.PARAMETER Quarantine
If present the specified device is quarantined.
.PARAMETER Unquarantine
If present the specified device is unquarantined.
.PARAMETER Device
An array of Device objects. Can be passed through the pipeline.
.PARAMETER Id
Indicates that you want to save the specified credentials in the local credential store.
.PARAMETER Menu
Connects to a server from the list of recently connected servers.
.OUTPUTS
A Server Object
.NOTES
-------------------------- Example 1 --------------------------
Connect-CBCServer -Server "http://server.cbc" -Org "MyOrg" -Token "MyToken"
Connects with the specified Server, Org, Token.

-------------------------- Example 2 --------------------------
Connect-CBCServer -Server "http://server1.cbc" -Org "MyOrg1" -Token "MyToken1" -SaveCredential
Connect with the specified Server, Org, Token and saves the credential in the Credential file.

-------------------------- Example 3 --------------------------
Connect-CBCServer -Menu
It prints the available Servers from the Credential file so that the user can choose with which one to connect.

.LINK

Online Version: http://devnetworketc/
#>
using module ../PSCarbonBlackCloud.Classes.psm1
function Set-CBCDevice {
    Param(
        [switch]$Quarantine,

        [switch]$Unquarantine,

        [Parameter(ParameterSetName = "Device", ValueFromPipeline = $true)]
        [array]$Device,

        [Parameter(ParameterSetName = "Id")]
        [string[]] $Id,

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
            $Body["device_id"] = $Id
            $Body["options"] = @{
                "toggle" = "ON"
            }
            switch ($PSCmdlet.ParameterSetName) {
                "Device" {
                    $ids = [System.Collections.ArrayList]@()
                    foreach ($device in $Device) {
                        $ids.Add($device.Id)
                    }
                    Write-Host $ids
                    $Body["device_id"] = $ids
                    $jsonBody = ConvertTo-Json -InputObject $Body
                    $ExecuteTo | ForEach-Object {
                        $Response = Invoke-CBCRequest -Server $_ `
                            -Endpoint $CBC_CONFIG.endpoints["Devices"]["Quarantine"] `
                            -Method POST `
                            -Body $jsonBody
                    }
                }
                "Id" {
                    $jsonBody = ConvertTo-Json -InputObject $Body
                    $ExecuteTo | ForEach-Object {
                        $Response = Invoke-CBCRequest -Server $_ `
                            -Endpoint $CBC_CONFIG.endpoints["Devices"]["Quarantine"] `
                            -Method POST `
                            -Body $jsonBody
                    }
                }
            }
            return $Response
        }
        if ($Unquarantine) {
            $Body = @{}
            $Body["action_type"] = "QUARANTINE"
            $Body["device_id"] = $Id
            $Body["options"] = @{
                "toggle" = "OFF"
            }
            switch ($PSCmdlet.ParameterSetName) {
                "Device" {
                    $ids = [System.Collections.ArrayList]@()
                    foreach ($device in $Device) {
                        $ids.Add($device.Id)
                    }
                    Write-Host $ids
                    $Body["device_id"] = $ids
                    $jsonBody = ConvertTo-Json -InputObject $Body
                    $ExecuteTo | ForEach-Object {
                        $Response = Invoke-CBCRequest -Server $_ `
                            -Endpoint $CBC_CONFIG.endpoints["Devices"]["Quarantine"] `
                            -Method POST `
                            -Body $jsonBody
                    }
                }
                "Id" {
                    $jsonBody = ConvertTo-Json -InputObject $Body
                    $ExecuteTo | ForEach-Object {
                        $Response = Invoke-CBCRequest -Server $_ `
                            -Endpoint $CBC_CONFIG.endpoints["Devices"]["Quarantine"] `
                            -Method POST `
                            -Body $jsonBody
                    }
                }
            }
            return $Response
        }
    }
}