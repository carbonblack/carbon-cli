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

    Param(
        [switch] $All,

        [array] $Id,

        [hashtable] $Criteria,

        [hashtable] $Exclusions,

        [string] $Query,

        [int] $Rows = 20,

        [int] $Start = 0,

        [PSCustomObject] $Server

    )
    Process {

        $ExecuteTo = $CBC_CONFIG.currentConnections
        if ($Server) {
            $ExecuteTo = @($Server)
        }

        $Results = @{}

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
            $Results = [System.Collections.ArrayList]@()

            $ResponseContent.results | ForEach-Object {
                $Results[$ServerName].Add([PSCarbonBlackCloud.Device]@{
                    Id = $_.id
                }) | Out-Null
            }
        }
        # TODO: Replicate the Get-Modules cmdlet, like it says the different libs for modules
        # we gonna do the same thing with the different Organizations.
        return $Results
    }
}