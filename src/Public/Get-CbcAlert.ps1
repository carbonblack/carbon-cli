using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all alerts from all valid connections. The returned CbcAlert object is a "base" alert object, 
common for the different alert types such as CbAnalytics, Device Control, Watchlist, Container Runtime, Host-Based Firewall 
and is complient with the corrsponding base alert object API schema: 
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/alerts-api/#fields
.SYNOPSIS
This cmdlet returns all alerts from all valid connections. The returned CbcAlert object is a "base" alert object, 
common for the different alert types such as CbAnalytics, Device Control, Watchlist and is complient with the corrsponding
base alert object API schema: 
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/alerts-api/#fields
.PARAMETER Category
Filter param: Specify the category of the alerts to retrieve. Available values: THREAT, MONITORED.
.PARAMETER DeviceId
Filter param: Specify the Id of the device for which to retrieve alerts.
.PARAMETER Id
Filter param: Specify the Id of the alert to retrieve.
.PARAMETER Include
Sets the criteria for the search.
.PARAMETER MaxResults
Set the max number of results (default is 50 and max is 10k).
.PARAMETER MinSeverity
Filter param: Specify the minimal severity оf the alerts to retrieve.
.PARAMETER PolicyName
Filter param: Specify the name of the policy associated with the device at the time of the alert.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.PARAMETER ThreatId
Filter param: Specify the id of the threat belonging to the alerts to retrieve. 
Threats are comprised of a combination of factors that can be repeated across devices.
.PARAMETER Type
Filter param: Specify the Type оf the alerts to retrieve.
Available values: CB_ANALYTICS, CONTAINER_RUNTIME, DEVICE_CONTROL, HOST_BASED_FIREWALL, WATCHLIST.
.OUTPUTS
CbcAlert[]
.NOTES
.EXAMPLE
PS > Get-CbcAlert

Returns all alerts from all connections. 
If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > Get-CbcAlert -Server $SpecifiedServer
.EXAMPLE
PS > Get-CbcAlert -Id "11a1a1a1-b22b-3333-44cc-dd5555d5d55d", "924a237d-443c-4965-b5b2-6fffcdff1d5b"

Returns the alerts with specified Ids.

.EXAMPLE

The criteria for
$criteria = @{
    "category" = @("<string>", "<string>"),
    "create_time" = @{
        "end" = "<dateTime>",
        "range" = "<string>",
        "start" = "<dateTime>"
    },
    "device_id" = @("<long>", "<long>"),
    "device_name" = @("<string>", "<string>"),
    "device_os" = @("<string>", "<string>"),
    "device_os_version" = @("<string>", "<string>"),
    "device_username" = @("<string>", "<string>"),
    "first_event_time" = @{
        "end" = "<dateTime>",
        "range" = "<string>",
        "start" = "<dateTime>"
    },
    "group_results" = "<boolean>",
    "id" = @("<string>", "<string>"),
    "last_event_time" = @{
        "end" = "<dateTime>",
        "range" = "<string>",
        "start" = "<dateTime>"
    },
    "legacy_alert_id" = @("<string>", "<string>"),
    "minimum_severity" = "<integer>",
    "policy_id" = @("<long>", "<long>"),
    "policy_name" = @("<string>", "<string>"),
    "process_name" = @("<string>", "<string>"),
    "process_sha256" = @("<string>", "<string>"),
    "reputation" = @("<string>", "<string>"),
    "tag" = @("<string>", "<string>"),
    "target_value" = @("<string>", "<string>"),
    "threat_id" = @("<string>", "<string>"),
    "type" = @("<string>", "<string>"),
    "last_update_time" = @{
        "end" = "<dateTime>",
        "range" = "<string>",
        "start" = "<dateTime>"
    },
    "workflow" = @("<string>", "<string>"),
}

Include parameters expect a hash table object

PS > Get-CbcAlert -Include $Criteria

Returns all alerts which correspond to the specified criteria.

PS > Get-CbcDevice -Include @{"type"= @("CB_ANALYTICS")
>>  "minimum_severity" = 3 }

PS > $IncludeCriteria = @{}
PS > $IncludeCriteria.type = @("CB_ANALYTICS")
PS > $IncludeCriteria.minimum_severity = 3
Get-CbcAlert -Include $IncludeCriteria

Returns all devices which correspond to the specified include criteria

.EXAMPLE
PS > Get-CbcAlert -Id "cfdb1201-fd5d-90db-81bb-b66ac9348f14" | foreach { Set-CbcDevice -Id $_.DeviceID -QuarantineEnabled $true }

Quarantines all devices that contain alert with id = "cfdb1201-fd5d-90db-81bb-b66ac9348f14".

.EXAMPLE
PS > $IncludeCriteria = @{}
PS > $IncludeCriteria.type = @("CB_ANALYTICS")
PS > $IncludeCriteria.minimum_severity = 3
PS > Get-CbcAlert -Include $IncludeCriteria | foreach { Set-CbcDevice -Id $_.DeviceID -QuarantineEnabled $true }

Quarantines all devices that contain analytics alerts with severity 3 or higher
.EXAMPLE
PS > Get-CbcAlert -Category THREAT -MinSeverity 4

Returns all THREAT alerts with severity equal or higher than 4

.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/alerts-api/
#>

function Get-CbcAlert {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcAlert[]])]
    param(
        [Parameter(ParameterSetName = "Default")]
        [string[]]$Category,

        [Parameter(ParameterSetName = "Default")]
        [string[]]$DeviceId,

        [Parameter(ParameterSetName = "Id", Position = 0)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "IncludeExclude")]
        [hashtable]$Include,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "IncludeExclude")]
        [int32]$MaxResults = 50,

        [Parameter(ParameterSetName = "Default")]
        [int]$MinSeverity,

        [Parameter(ParameterSetName = "Default")]
        [string[]]$PolicyName,

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "IncludeExclude")]
        [CbcServer[]]$Server,

        [Parameter(ParameterSetName = "Default")]
        [string[]]$ThreatId,

        [Parameter(ParameterSetName = "Default")]
        [string[]]$Type
    )

    process {

        if ($Server) {
            $ExecuteServers = $Server
        }
        else {
            $ExecuteServers = $global:DefaultCbcServers
        }

        switch ($PSCmdlet.ParameterSetName) {
            "Default" {
                $ExecuteServers | ForEach-Object {
                    $CurrentServer = $_
                    $RequestBody = @{}
                    $RequestBody.criteria = @{}

                    if ($PSBoundParameters.ContainsKey("DeviceId")) {
                        $RequestBody.criteria.device_id = $DeviceId
                    }

                    if ($PSBoundParameters.ContainsKey("Category")) {
                        $RequestBody.criteria.category = $Category
                    }

                    if ($PSBoundParameters.ContainsKey("PolicyName")) {
                        $RequestBody.criteria.policy_name = $PolicyName
                    }

                    if ($PSBoundParameters.ContainsKey("ThreatId")) {
                        $RequestBody.criteria.threat_id = $ThreatId
                    }

                    if ($PSBoundParameters.ContainsKey("Type")) {
                        $RequestBody.criteria.type = $Type
                    }

                    if ($PSBoundParameters.ContainsKey("MinSeverity")) {
                        $RequestBody.criteria.minimum_severity = $MinSeverity
                    }

                    $RequestBody.rows = $MaxResults

                    $RequestBody = $RequestBody | ConvertTo-Json

                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Alerts"]["Search"] `
                        -Method POST `
                        -Server $_ `
                        -Body $RequestBody

                    if ($Response.StatusCode -ne 200) {
                        Write-Error -Message $("Cannot get alerts for $($_)")
                    }
                    else {
                        $JsonContent = $Response.Content | ConvertFrom-Json

                        $JsonContent.results | ForEach-Object {
                            return Initialize-CbcAlert $_ $CurrentServer
                        }
                    }
                }
            }
            "IncludeExclude" {
                $ExecuteServers | ForEach-Object {
                    $CurrentServer = $_

                    $RequestBody = @{}
                    if ($Include) {
                        $RequestBody.criteria = $Include
                    }
                    $RequestBody.rows = $MaxResults

                    $RequestBody = $RequestBody | ConvertTo-Json

                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Alerts"]["Search"] `
                        -Method POST `
                        -Server $_ `
                        -Body $RequestBody

                    if ($Response.StatusCode -ne 200) {
                        Write-Error -Message $("Cannot get alerts for $($_)")
                    }
                    else {
                        $JsonContent = $Response.Content | ConvertFrom-Json

                        $JsonContent.results | ForEach-Object {
                            return Initialize-CbcAlert $_ $CurrentServer
                        }
                    }
                }
            }
            "Id" {
                $ExecuteServers | ForEach-Object {
                    $CurrentServer = $_
                    $RequestBody = @{}
                    $RequestBody.rows = $MaxResults
                    $RequestBody.criteria = @{"id" = $Id }
                    $RequestBody = $RequestBody | ConvertTo-Json

                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Alerts"]["Search"] `
                        -Method POST `
                        -Server $CurrentServer `
                        -Body $RequestBody
                    
                    if ($Response.StatusCode -ne 200) {
                        Write-Error -Message $("Cannot get alerts for $($_)")
                    }
                    else {
                        $JsonContent = $Response.Content | ConvertFrom-Json
                        $JsonContent.results | ForEach-Object {
                            return Initialize-CbcAlert $_ $CurrentServer
                        }
                    }
                } 
            }
        }
    }
}