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
.OUTPUTS


.LINK

Online Version: http://devnetworketc/
#>
function Get-CBCDevice {

    [CmdletBinding(DefaultParameterSetName = "All")]
    Param(
        [Parameter(ParameterSetName = "All")]
        [switch] $All,

        [Parameter(ParameterSetName = "GetOne")]
        [ValidateNotNullOrEmpty()]
        [string] $Id,

        [Parameter(ParameterSetName = "All")]
        [hashtable] $Criteria,

        [Parameter(ParameterSetName = "All")]
        [hashtable] $Exclusions,

        [Parameter(ParameterSetName = "All")]
        [string] $Query,

        [Parameter(ParameterSetName = "All")]
        [int] $Rows,

        [Parameter(ParameterSetName = "All")]
        [int] $Start

    )
    Process {
        switch ($PSCmdlet.ParameterSetName) {
            "All" {
                $Body = "{}" | ConvertFrom-Json

                if ($Criteria) {
                    $Body | Add-Member -Name "criteria" -Value $Criteria -MemberType NoteProperty
                }

                if ($Exclusions) {
                    $Body | Add-Member -Name "exclusions" -Value $Exclusions -MemberType NoteProperty
                }

                if ($Query) {
                    $Body | Add-Member -Name "query" -Value $Exclusions -MemberType NoteProperty
                }
                
                if ($Rows) {
                    $Body | Add-Member -Name "rows" -Value $Rows -MemberType NoteProperty
                }

                if ($Start) {
                    $Body | Add-Member -Name "start" -Value $Start -MemberType NoteProperty
                }

                $jsonBody = ConvertTo-Json -InputObject $Body
                $response = Invoke-CBCRequest -Uri $CBC_CONFIG.endpoints.Devices.Search -Method POST -Body $jsonBody
            }
            "GetOne" {
                $response = Invoke-CBCRequest -Uri CBC_CONFIG.endpoints.Devices.SpecificDeviceInfo -Method GET -Params @($ID)
            }
        }

        $result = @()
        foreach($org in ($response | Select-Object -ExpandProperty Keys)) {
            $result += $response[$org].Content | ConvertFrom-Json -AsHashtable
        }

        $result
    }
}