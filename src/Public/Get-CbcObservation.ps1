using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all observations from all valid connections. The retrieval of observation includes two API requests
first to start a job with specific criteria/query. The second one is getting the results based on the job that was created.
The second API request is asynchronous, so we need to make sure all of the results are available, before returning the results.
.PARAMETER Alert
Returns the observations with the specified CbcAlert.
.PARAMETER AlertId
Returns the observations with the specified AlertIds.
.PARAMETER DeviceId
Returns the observations with the specified DeviceIds.
.PARAMETER EventType
Returns the observations with the specified EventTypes.
.PARAMETER Exclude
Sets the exclusions for the search. Either query or criteria/exclusions must be included.
.PARAMETER Id
Returns the observations with the specified Ids.
.PARAMETER Include
Sets the criteria for the search. Either query or criteria/exclusions must be included.
.PARAMETER MaxResults
Set the max number of results (default is 500 and max is 10k).
.PARAMETER ObservationType
Returns the observations with the specified ObservationTypes.
.PARAMETER Query
Set the query - query is in lucene syntax and/or including value searches. Either query or criteria/exclusions must be included.
.OUTPUTS
CbcObservation[]
.NOTES
Permissions needed: READ, CREATE org.search.events
.EXAMPLE
PS > Get-CbcObservation -Id "95016925089911ee9568b74cff311:23f4c71a-e350-8576-f832-0b0968f", "95016925089911ee9568b74cff311:23f4c71a-e350-8576-f832-0b0968f"

Returns the observations with specified Ids.
.EXAMPLE
The criteria for
PS > $criteria = @{"alert_category" = @("THREAT")}
PS > Get-CbcObservation -Include $Criteria -Id "95016925089911ee9568b74cff311:23f4c71a-e350-8576-f832-0b0968f"

Include parameters expect a hash table object
Returns all alerts which correspond to the specified criteria and Ids.
.EXAMPLE
PS > Get-CbcObservation -Include @{"alert_category" = @("THREAT")}

Returning all the observations that are in the THREAT alert category.
.EXAMPLE
PS > Get-CbcObservation -AlertId "b01dad69-09e8-71ba-6542-60f5a8d58030" -ObservationType "CB_ANALYTICS" -EventType "childproc" -DeviceId 1111111 

You can filter by AlertId, DeviceId, EventType, ObservationType
.EXAMPLE
PS > Get-CbcObservation -Query "alert_id:b01dad69-09e8-71ba-6542-60f5a8d58030"

You can provide query in lucene syntax.
.EXAMPLE
PS > Get-CbcAlert -Id "982e5f1c-e893-5914-cea9-3478f88e9ef1" | Get-CbcObservation

Returns the observations with that Alert
.LINK
Full list of searchable fields: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/platform-search-fields
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/observations-api
#>

function Get-CbcObservation {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcObservation[]])]
    param(
        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Filter")]
        [string[]]$AlertId,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Filter")]
        [string[]]$DeviceId,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Filter")]
        [string[]]$EventType,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Filter")]
        [string[]]$ObservationType,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Id", Position = 0)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "IncludeExclude", Mandatory = $true)]
        [hashtable]$Include,

        [Parameter(ParameterSetName = "IncludeExclude")]
        [hashtable]$Exclude,

        [Parameter(ParameterSetName = "Query", Mandatory = $true)]
        [string]$Query,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Filter")]
        [Parameter(ParameterSetName = "Query")]
        [Parameter(ParameterSetName = "IncludeExclude")]
        [int32]$MaxResults = 500,

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Filter")]
        [Parameter(ParameterSetName = "Query")]
        [Parameter(ParameterSetName = "IncludeExclude")]
        [CbcServer[]]$Server,

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Filter")]
        [Parameter(ParameterSetName = "Query")]
        [Parameter(ParameterSetName = "IncludeExclude")]
        [switch]$AsJob,

        [Parameter(ValueFromPipeline = $true,
			Mandatory = $true,
			Position = 0,
			ParameterSetName = "Alert")]
		[CbcAlert[]]$Alert
    )
    process {
        if ($Server) {
            $ExecuteServers = $Server
        }
        else {
            $ExecuteServers = $global:DefaultCbcServers
        }
        $Endpoint = $global:CBC_CONFIG.endpoints["Observations"]

        if ($PSCmdlet.ParameterSetName -eq "Alert") {
            $AlertGroups = $Alert | Group-Object -Property Server
            foreach ($Group in $AlertGroups) {
                $RequestBody = @{}
                $RequestBody.rows = $MaxResults
                $RequestBody.criteria = @{}
                $RequestBody.criteria.alert_id = @()
                foreach ($CurrAlert in $Group.Group) {
                    $RequestBody.criteria.alert_id += $CurrAlert.Id
                    $CurrentServer = $CurrAlert.Server
                }
                return Create-Job $Endpoint $RequestBody "observation_search" $CurrentServer
            }
        }
        else {
            $ExecuteServers | ForEach-Object {
                $RequestBody = @{}
                $RequestBody.rows = $MaxResults
                switch ($PSCmdlet.ParameterSetName) {
                    "Default" {
                        $RequestBody.criteria = @{}
                        if ($PSBoundParameters.ContainsKey("Id")) {
                            $RequestBody.criteria.observation_id = $Id
                        }
                        if ($PSBoundParameters.ContainsKey("AlertId")) {
                            $RequestBody.criteria.alert_id = $AlertId
                        }
                        if ($PSBoundParameters.ContainsKey("DeviceId")) {
                            $RequestBody.criteria.device_id = $DeviceId
                        }
                        if ($PSBoundParameters.ContainsKey("EventType")) {
                            $RequestBody.criteria.event_type = $EventType
                        }
                        if ($PSBoundParameters.ContainsKey("ObservationType")) {
                            $RequestBody.criteria.observation_type = $ObservationType
                        }
                    }
                    "IncludeExclude" {
                        if ($PSBoundParameters.ContainsKey("Include")) {
                            $RequestBody.criteria = $Include
                        }
                        if ($PSBoundParameters.ContainsKey("Exclude")) {
                            $RequestBody.exclusions = $Exclude
                        }
                    }
                    "Query" {
                        if ($PSBoundParameters.ContainsKey("Query")) {
                            $RequestBody.query = $Query
                        }
                    }
                }
                return Create-Job $Endpoint $RequestBody "observation_search" $_
            }
        }
    }
}
