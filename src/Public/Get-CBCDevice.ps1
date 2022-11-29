using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all devices or a specific device with every current connection.

.PARAMETER All
Returns all devices.
.PARAMETER Id
Returns a device with specified ID.
.PARAMETER Criteria
Sets the criteria for the search.
.PARAMETER Exclusions
Sets the exclusions for the search.
.PARAMETER Query
Set the query in lucene syntax for the search.
.PARAMETER Rows
Set the max num of returned rows (default is 20 and max is 20k).
.PARAMETER Start
Set the start of the row (default is 0 and Rows + Start should not exceed 10k).
.PARAMETER CBCServer
Sets a specified CBC Server from the current connections to execute the cmdlet with.
.OUTPUTS
A Device Object.
.NOTES
-------------------------- Example 1 --------------------------
Get-CBCDevice
It returns all devices and the request is made with all current connections.

-------------------------- Example 2 --------------------------
Get-CBCDevice -All
It returns all devices and the request is made with all current connections.

-------------------------- Example 3 --------------------------
Get-CBCDevice -Id "12345"
It returns the device with specified Id and the request is made with all current connections.

-------------------------- Example 4 --------------------------
Get-CBCDevice "12345"
It returns the device with specified Id and the request is made with all current connections.

-------------------------- Example 5 --------------------------
Get-CBCDevice -All -CBCServer $CBCServer
It returns all devices but the request is made only with the connection with specified CBC server.

-------------------------- Example 6 --------------------------
Get-CBCDevice -Id "12345" -CBCServer $CBCServer
It returns the device with specified Id but the request is made only with the connection with specified CBC server.

-------------------------- Example 7 --------------------------
$Criteria = 
@{
    "criteria" = @{
      "status" = [ "<string>", "<string>" ],
      "os" = [ "<string>", "<string>" ],
      "lastContactTime" = {
        "end" = "<dateTime>",
        "range" = "<string>",
        "start" = "<dateTime>"
      },
      "adGroupId" = [ "<long>", "<long>" ],
      "policyId" = [ "<long>", "<long>" ],
      "id" = [ "<long>", "<long>" ],
      "targetPriority" = [ "<string>", "<string>" ],
      "deploymentType" = [ "<string>", "<string>" ],
      "vmUuid" = [ "<string>", "<string>" ],
      "vcenterUuid" = [ "<string>", "<string>" ],
      "osVersion" = [ "<string>", "<string>" ],
      "sensorVersion" = [ "<string>", "<string>" ],
      "signatureStatus" = [ "<string>", "<string>" ],
      "goldenDeviceStatus" = [ "<string>", "<string>" ],
      "goldenDeviceId" = [ "<string>", "<string>" ],
      "cloudProviderTags" = [ "<string>", "<string>" ],
      "virtualPrivateCloudId" = [ "<string>", "<string>" ],
      "autoScalingGroupName" = [ "<string>", "<string>" ],
      "cloudProviderAccountId" = [ "<string>", "<string>" ],
      "cloudProviderResourceId" = [ "<string>", "<string>" ],
      "virtualizationProvider" = [ "<string>", "<string>" ],
      "subDeploymentType" = [ "<string>", "<string>" ],
      "baseDevice" = "<boolean>",
      "hostBasedFirewallStatus" = [ "<string>", "<string>" ],
      "hostBasedFirewallReason" = "<string>",
      "hostBasedFirewallSensorObservedState" = "<string>",
      "vcenterHostUrl" = [ "<string>", "<string>" ]
    }
}
Get-CBCDevice -All -Criteria $Criteria
It returns all devices which correspond to the specified criteria.

-------------------------- Example 8 --------------------------
$Exclusions = @{
    "exclusions" = {
      "sensor_version" = ["<string>"]
    }
}
Get-CBCDevice -All -Exclusions $Exclusions 
It returns all devices which correspond to the specified exclusions.

-------------------------- Example 9 --------------------------
$Query = "os:LINUX"
Get-CBCDevice -All -Query $Query
It returns all devices which correspond to the specified query with lucene syntax.

-------------------------- Example 10 --------------------------
Get-CBCDevice -All -Criteria $Criteria -Exclusions $Exclusions -Query $Query -Rows 20 -Start 0
It returns all devices which correspond to the specified criteria build with the specified params (Exclusion, Query, Rows and Start).
.LINK
Online Version: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/devices-api/
#>

function Get-CBCDevice {
    [CmdletBinding(DefaultParameterSetName = "NoParams")]
    Param(
        [Parameter(ParameterSetName = "all", Position = 0)]
        [switch] $All,

        [Parameter(ParameterSetName = "id", Position = 0)]
        [array] $Id,

        [Parameter(ParameterSetName = "all")]
        [hashtable] $Criteria,

        [Parameter(ParameterSetName = "all")]
        [hashtable] $Exclusions,

        [Parameter(ParameterSetName = "all")]
        [string] $Query,

        [Parameter(ParameterSetName = "all")]
        [int] $Rows = 20,

        [Parameter(ParameterSetName = "all")]
        [int] $Start = 0,

        [CBCServer] $CBCServer

    )
    Process {

        $ExecuteTo = $CBC_CONFIG.currentConnections
        if ($CBCServer) {
            $ExecuteTo = @($CBCServer)
        }

        switch ($PSCmdlet.ParameterSetName) {
            "NoParams" {
                $Body = "{}" | ConvertFrom-Json
                $jsonBody = ConvertTo-Json -InputObject $Body

                $ExecuteTo | ForEach-Object {
                    $CurrentCBCServer = $_
                    $CBCServerName = "[{0}] {1}" -f $_.Org, $_.Uri
                    $Response = Invoke-CBCRequest -CBCServer $_ `
                        -Endpoint $CBC_CONFIG.endpoints["Devices"]["Search"] `
                        -Method POST `
                        -Body $jsonBody
                    if ($null -ne $Response) {
                        $ResponseContent = $Response.Content | ConvertFrom-Json
                        Write-Host "`r`n`tDevices from: $CBCServerName`r`n"
                        $ResponseContent.results | ForEach-Object {
                            $CurrentDevice = $_
                            $DeviceObject = [Device]::new()
                            $DeviceObject.CBCServer = $CurrentCBCServer
                            ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                                $key = (ConvertTo-PascalCase $_)
                                $value = $CurrentDevice.$_
                                $DeviceObject.$key = $value
                            }
                            $DeviceObject 
                        }
                    }
                    else {
                        return [Device]::new()
                    }
                }
            }
            "all" {
                $Body = "{}" | ConvertFrom-Json

                if ($Criteria) {
                    $Body | Add-Member -Name "criteria" -Value $Criteria -MemberType NoteProperty
                }

                if ($Exclusions) {
                    $Body | Add-Member -Name "exclusions" -Value $Exclusions -MemberType NoteProperty
                }

                if ($Id) {
                    $Body | Add-Member -Name "id" -Value $Id -MemberType NoteProperty
                }

                if ($Query) {
                    $Body | Add-Member -Name "query" -Value $Query -MemberType NoteProperty
                }
        
                if ($Rows) {
                    $Body | Add-Member -Name "rows" -Value $Rows -MemberType NoteProperty
                }

                if ($Start) {
                    $Body | Add-Member -Name "start" -Value $Start -MemberType NoteProperty
                }

                $jsonBody = ConvertTo-Json -InputObject $Body

                $ExecuteTo | ForEach-Object {
                    $CurrentCBCServer = $_
                    $CBCServerName = "[{0}] {1}" -f $_.Org, $_.Uri
                    $Response = Invoke-CBCRequest -CBCServer $_ `
                        -Endpoint $CBC_CONFIG.endpoints["Devices"]["Search"] `
                        -Method POST `
                        -Body $jsonBody
                    
                    if ($null -ne $Response) {
                        $ResponseContent = $Response.Content | ConvertFrom-Json
                    
                        Write-Host "`r`n`tDevices from: $CBCServerName`r`n"
                        $ResponseContent.results | ForEach-Object {
                            $CurrentDevice = $_
                            $DeviceObject = [Device]::new()
                            $DeviceObject.CBCServer = $CurrentCBCServer
                        ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                                $key = (ConvertTo-PascalCase $_)
                                $value = $CurrentDevice.$_
                                $DeviceObject.$key = $value
                            }
                            $DeviceObject 
                        }
                    } 
                    else {
                        return [Device]::new()
                    }
                    
                }
            }
            "id" {
                $ExecuteTo | ForEach-Object {
                    $CurrentCBCServer = $_
                    $CBCServerName = "[{0}] {1}" -f $_.Org, $_.Uri
                    $Response = Invoke-CBCRequest -CBCServer $_ `
                        -Endpoint $CBC_CONFIG.endpoints["Devices"]["SpecificDeviceInfo"] `
                        -Method GET `
                        -Params @($Id)
        
                    if ($null -ne $Response) {
                        $ResponseContent = $Response.Content | ConvertFrom-Json
                    
                        Write-Host "`r`n`tDevices from: $CBCServerName`r`n"
                        $ResponseContent | ForEach-Object {
                            $CurrentDevice = $_
                            $DeviceObject = [Device]::new()
                            $DeviceObject.CBCServer = $CurrentCBCServer
                        ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                                $key = (ConvertTo-PascalCase $_)
                                $value = $CurrentDevice.$_
                                $DeviceObject.$key = $value
                            }
                            $DeviceObject 
                        }
                    }
                    else {
                        return [Device]::new()
                    }
                    
                }
            }
        }

    }
}