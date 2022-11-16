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
Set the query for the search.
.PARAMETER Rows
Set the max num of returned rows.
.PARAMETER Start
Set the start of the row.
.PARAMETER Server
Specifies the Server 
.OUTPUTS

.NOTES
-------------------------- Example 1 --------------------------
Get-CBCDevice -All
It returns all devices and the request is made with all current connections.

-------------------------- Example 2 --------------------------
Get-CBCDevice -Id "SomeId"
It returns the device with specified Id and the request is made with all current connections.

-------------------------- Example 3 --------------------------
Get-CBCDevice -All -Server $Server
It returns all devices but the request is made only with the connection with specified server.

-------------------------- Example 4 --------------------------
Get-CBCDevice -Id "SomeId" -Server $Server
It returns the device with specified Id but the request is made only with the connection with specified server.

-------------------------- Example 5 --------------------------
Get-CBCDevice -All -Criteria $Criteria
It returns all devices which correspond to the specified criteria.

-------------------------- Example 6 --------------------------
Get-CBCDevice -All -Exclusions $Exclusions -Query "SomeQuery" -Rows N (the default is 20) -Start N (the default is 0)
It returns all devices which correspond to the specified criteria build with the specified params (Exclusion, Query, Rows and Start).

.LINK

Online Version: http://devnetworketc/
#>
function Get-CBCDevice {

    Param(
        [Parameter(ParameterSetName = "all")]
        [switch] $All,

        [Parameter(ParameterSetName = "id")]
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

        [PSCustomObject] $Server

    )
    Process {

        $ExecuteTo = $CBC_CONFIG.currentConnections
        if ($Server) {
            $ExecuteTo = @($Server)
        }

        # $Results = @{}
        switch ($PSCmdlet.ParameterSetName) {

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
                    $ServerName = "[{0}] {1}" -f $_.Org, $_.Uri
                    $Response = Invoke-CBCRequest -Server $_ `
                        -Endpoint $CBC_CONFIG.endpoints["Devices"]["Search"] `
                        -Method POST `
                        -Body $jsonBody
        
                    $ResponseContent = $Response.Content | ConvertFrom-Json
                    
                    Write-Host "`r`n`tDevices from: $ServerName`r`n"
                    $ResponseContent.results | ForEach-Object {
                        $CurrentDevice = $_
                        $DeviceObject = [PSCarbonBlackCloud.Device]@{}
                        ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                            $key = (ConvertTo-PascalCase $_)
                            $value = $CurrentDevice.$_
                            $DeviceObject.$key = $value
                        }
                        $DeviceObject 
                    }
                }
            }
            "id" {
                $ExecuteTo | ForEach-Object {
                    $ServerName = "[{0}] {1}" -f $_.Org, $_.Uri
                    $Response = Invoke-CBCRequest -Server $_ `
                        -Endpoint $CBC_CONFIG.endpoints["Devices"]["SpecificDeviceInfo"] `
                        -Method GET `
                        -Params @($Id)
        
                    $ResponseContent = $Response.Content | ConvertFrom-Json
                    
                    Write-Host "`r`n`tDevices from: $ServerName`r`n"
                    $ResponseContent | ForEach-Object {
                        $CurrentDevice = $_
                        $DeviceObject = [PSCarbonBlackCloud.Device]@{}
                        ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                            $key = (ConvertTo-PascalCase $_)
                            $value = $CurrentDevice.$_
                            $DeviceObject.$key = $value
                        }
                        $DeviceObject 
                    }
                }
            }
        }

    }
}