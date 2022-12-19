using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all alerts or a specific alert with every current connection.

.PARAMETER Id
Returns a device with specified ID.
.PARAMETER Criteria
Sets the criteria for the search.
.PARAMETER Query
Set the query in lucene syntax for the search.
.PARAMETER Rows
Set the max num of returned rows (default is 20 and max is 10k).
.PARAMETER Start
Set the start of the row (default is 0 and Rows + Start should not exceed 10k).
.PARAMETER CBCServer
Sets a specified CBC Server from the current connections to execute the cmdlet with.
.OUTPUTS
An Alert Object. There are four type of Alerts - CBAnalyticsAlert, DeviceControlAlert, WatchlistAlert and ContainerRuntimeAlert.
.NOTES
-------------------------- Example 1 --------------------------
Get-CBCAlert
It returns all alerts and the request is made with all current connections.

-------------------------- Example 2 --------------------------
Get-CBCAlert -Id "11a1a1a1-b22b-3333-44cc-dd5555d5d55d"
It returns the alert with specified Id and the request is made with all current connections.

-------------------------- Example 3 --------------------------
Get-CBCAlert "11a1a1a1-b22b-3333-44cc-dd5555d5d55d"
It returns the alert with specified Id and the request is made with all current connections.

-------------------------- Example 4 --------------------------
Get-CBCAlert -CBCServer $CBCServer
It returns all alerts but the request is made only with the connection with specified CBC server.

-------------------------- Example 5 --------------------------
Get-CBCAlert -Id "11a1a1a1-b22b-3333-44cc-dd5555d5d55d" -CBCServer $CBCServer
It returns the alert with specified Id but the request is made only with the connection with specified CBC server.

-------------------------- Example 6 --------------------------
$criteria = @{
    "criteria" = @{
        "category" = ["<string>", "<string>"],
        "create_time" = @{
            "end" = "<dateTime>",
            "range" = "<string>",
            "start" = "<dateTime>"
        },
        "device_id" = ["<long>", "<long>"],
        "device_name" = ["<string>", "<string>"],
        "device_os" = ["<string>", "<string>"],
        "device_os_version" = ["<string>", "<string>"],
        "device_username" = ["<string>", "<string>"],
        "first_event_time" = @{
            "end" = "<dateTime>",
            "range" = "<string>",
            "start" = "<dateTime>"
        },
        "group_results" = "<boolean>",
        "id" = ["<string>", "<string>"],
        "last_event_time" = @{
            "end" = "<dateTime>",
            "range" = "<string>",
            "start" = "<dateTime>"
        },
        "legacy_alert_id" = ["<string>", "<string>"],
        "minimum_severity" = "<integer>",
        "policy_id" = ["<long>", "<long>"],
        "policy_name" = ["<string>", "<string>"],
        "process_name" = ["<string>", "<string>"],
        "process_sha256" = ["<string>", "<string>"],
        "reputation" = ["<string>", "<string>"],
        "tag" = ["<string>", "<string>"],
        "target_value" = ["<string>", "<string>"],
        "threat_id" = ["<string>", "<string>"],
        "type" = ["<string>", "<string>"],
        "last_update_time" = @{
            "end" = "<dateTime>",
            "range" = "<string>",
            "start" = "<dateTime>"
        },
        "workflow" = ["<string>", "<string>"],
    }
}
Get-CBCAlert -Criteria $Criteria
It returns all alerts which correspond to the specified criteria.

-------------------------- Example 7 --------------------------
Get-CBCAlert -Query "device_id:123456789"
It returns all alerts which correspond to the specified query with lucene syntax.

-------------------------- Example 8 --------------------------
Get-CBCAlert -Criteria $Criteria -Query $Query -Rows 20 -Start 0
It returns all alerts which correspond to the specified criteria build with the specified params (Query, Rows and Start).

.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/alerts-api/
#>
function Get-CBCAlert {
    [CmdletBinding(DefaultParameterSetName = "all")]
    Param(
        [Parameter(ParameterSetName = "id", Position = 0)]
        [array] $Id,

        [Parameter(ParameterSetName = "all")]
        [hashtable] $Criteria,

        [Parameter(ParameterSetName = "all")]
        [string] $Query,

        [Parameter(ParameterSetName = "all")]
        [int] $Rows = 20,

        [Parameter(ParameterSetName = "all")]
        [int] $Start = 0,

        [CBCServer] $CBCServer
    )

    Process {
        if ($CBC_CONFIG.currentConnections) {
            $ExecuteTo = $CBC_CONFIG.currentConnections
        }
        else {
            Write-Error "There is no active connection!" -ErrorAction "Stop"
        }
        
        if ($CBCServer) {
            $ExecuteTo = @($CBCServer)
        }

        switch ($PSCmdlet.ParameterSetName) {
            "all" {
                $Body = "{}" | ConvertFrom-Json

                if ($Criteria) {
                    $Body | Add-Member -Name "criteria" -Value $Criteria -MemberType NoteProperty
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
                    $Response = Invoke-CBCRequest -CBCServer $CurrentCBCServer `
                        -Endpoint $CBC_CONFIG.endpoints["Alert"]["Search"] `
                        -Method POST `
                        -Body $jsonBody
                    
                    Get-AlertAPIResponse $Response $CBCServerName $CurrentCBCServer
                }
            }
            "id" {
                $ExecuteTo | ForEach-Object {
                    $CurrentCBCServer = $_
                    $CBCServerName = "[{0}] {1}" -f $_.Org, $_.Uri
                    $Response = Invoke-CBCRequest -CBCServer $CurrentCBCServer `
                        -Endpoint $CBC_CONFIG.endpoints["Alert"]["SpecificAlert"] `
                        -Method GET `
                        -Params @($Id)
                    
                    Get-AlertAPIResponse $Response $CBCServerName $CurrentCBCServer
                }
            }
        }
    }
}