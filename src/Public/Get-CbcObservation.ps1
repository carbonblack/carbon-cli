using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all observations from all valid connections. The retrieval of observation includes two API requests
first to start a job with specific criteria/query. The second one is getting the results based on the job that was created.
The second API request is asynchronous, so we need to make sure all of the results are available, before returning the results.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/observations-api
.PARAMETER Exclude
Sets the exclusions for the search. Either query or criteria/exclusions must be included.
.PARAMETER Id
Returns the observations with the specified Ids.
.PARAMETER Include
Sets the criteria for the search. Either query or criteria/exclusions must be included.
.PARAMETER MaxResults
Set the max number of results (default is 500 and max is 10k).
.PARAMETER Query
Set the query - query is in lucene syntax and/or including value searches. Either query or criteria/exclusions must be included.
.OUTPUTS
CbcObservation[]
.NOTES
.EXAMPLE
PS > Get-CbcObservation

Returns all observations from all connections. 
If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > Get-CbcObservation -Server $SpecifiedServer
.EXAMPLE
PS > Get-CbcObservation -Id "11a1a1a1-b22b-3333-44cc-dd5555d5d55d", "924a237d-443c-4965-b5b2-6fffcdff1d5b"

Returns the observations with specified Ids.

.EXAMPLE

The criteria for
$criteria = @{
    "alert_category" = @("<string>"),
    ...
}

Include parameters expect a hash table object

PS > Get-CbcObservation -Include $Criteria

Returns all alerts which correspond to the specified criteria.

PS > Get-CbcObservation -Include @{"alert_category"= @("THREAT")}

Returns all observations which correspond to the specified include criteria

.LINK
Full list of searchable fields: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/platform-search-fields
#>

function Get-CbcObservation {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcObservation[]])]
    param(
        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Id", Position = 0)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "IncludeExclude")]
        [hashtable]$Include,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "IncludeExclude")]
        [int32]$MaxResults = 500,

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "IncludeExclude")]
        [CbcServer[]]$Server
    )

    process {
        if ($Server) {
            $ExecuteServers = $Server
        }
        else {
            $ExecuteServers = $global:CBC_CONFIG.currentConnections
        }

        switch ($PSCmdlet.ParameterSetName) {
            "Default" {
                $ExecuteServers | ForEach-Object {
                    $CurrentServer = $_
                    $RequestBody = @{}
                    $RequestBody.criteria = @{}

                    if ($PSBoundParameters.ContainsKey("Include")) {
                        $RequestBody.criteria = $Include
                    }

                    if ($PSBoundParameters.ContainsKey("Id")) {
                        $RequestBody.criteria.observation_id = $Id
                    }

                    if ($PSBoundParameters.ContainsKey("Exclude")) {
                        $RequestBody.exclusions = $Exclude
                    }
                    
                    $RequestBody.rows = $MaxResults

                    $RequestBody = $RequestBody | ConvertTo-Json

                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Observations"]["StartJob"] `
                        -Method POST `
                        -Server $_ `
                        -Body $RequestBody

                    if ($Response.StatusCode -ne 200) {
                        Write-Error -Message $("Cannot create observation search job for $($_)")
                    }
                    else {
                        # if search job is created, then we could get the results, but
                        # it is async request so to keep checking, till all are available
                        $JsonContent = $Response.Content | ConvertFrom-Json
                        # get the job_id to retrieve the results for this job
                        $JobId = $JsonContent.job_id
                        $Contacted = -1
                        $Completed = -2
                        $TimeOut = 0
                        $TimeOutFlag = false

                        # if contacted and completed are equal, this means we could get the results
                        while ($Contacted -ne $Completed) {
                            # sleep 0.5 to give it time to retrieve the results - it might still not be enough,
                            # so keep checking for 3 mins before timeout
                            $TimeOut += 0.5
                            Start-Sleep -Seconds 0.5
                            if ($TimeOut -gt 180) {
                                $TimeOutFlag = true
                                Write-Error -Message $("Cannot retrieve observations due to timeout for $($_)")
                                break
                            }

                            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Observations"]["Results"] `
                                -Method GET `
                                -Server $_ `
                                -Params @($JobId, "?start=0&rows=0")

                            $JsonContent = $Response.Content | ConvertFrom-Json
                            $Contacted = $JsonContent.contacted
                            $Completed = $JsonContent.completed
                        }

                        # if we did not fail due to timeout, then we could get the results
                        if (!$TimeOutFlag) {
                            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Observations"]["Results"] `
                                -Method GET `
                                -Server $_ `
                                -Params @($JobId, "?start=0&rows=" + $MaxResults)
                            $JsonContent = $Response.Content | ConvertFrom-Json

                            $JsonContent.results | ForEach-Object {
                                return Initialize-CbcObservation $_ $CurrentServer
                            }
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

                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Observations"]["StartJob"] `
                        -Method POST `
                        -Server $_ `
                        -Body $RequestBody

                    if ($Response.StatusCode -ne 200) {
                        Write-Error -Message $("Cannot create observation search job for $($_)")
                    }
                    else {
                        # if search job is created, then we could get the results, but
                        # it is async request so to keep checking, till all are available
                        $JsonContent = $Response.Content | ConvertFrom-Json
                        # get the job_id to retrieve the results for this job
                        $JobId = $JsonContent.job_id
                        $Contacted = -1
                        $Completed = -2
                        $TimeOut = 0
                        $TimeOutFlag = false

                        # if contacted and completed are equal, this means we could get the results
                        while ($Contacted -ne $Completed) {
                            # sleep 0.5 to give it time to retrieve the results - it might still not be enough,
                            # so keep checking for 180 before timeout
                            $TimeOut += 0.5
                            Start-Sleep -Seconds 0.5
                            if ($TimeOut -gt 180) {
                                $TimeOutFlag = true
                                Write-Error -Message $("Cannot retrieve observations due to timeout for $($_)")
                                break
                            }

                            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Observations"]["Results"] `
                                -Method GET `
                                -Server $_ `
                                -Params @($JobId, "?start=0&rows=0")

                            $JsonContent = $Response.Content | ConvertFrom-Json
                            $Contacted = $JsonContent.contacted
                            $Completed = $JsonContent.completed
                        }

                        # if we did not fail due to timeout, then we could get the results
                        if (!$TimeOutFlag) {
                            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Observations"]["Results"] `
                                -Method GET `
                                -Server $_ `
                                -Params @($JobId, "?start=0&rows=" + $MaxResults)
                            $JsonContent = $Response.Content | ConvertFrom-Json

                            $JsonContent.results | ForEach-Object {
                                return Initialize-CbcObservation $_ $CurrentServer
                            }
                        }
                    }
                }
            }
            "Id" {
                $ExecuteServers | ForEach-Object {
                    $CurrentServer = $_
                    $RequestBody = @{}
                    $RequestBody.rows = $MaxResults
                    $RequestBody.criteria = @{"observation_id" = $Id }
                    $RequestBody = $RequestBody | ConvertTo-Json

                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Observations"]["StartJob"] `
                        -Method POST `
                        -Server $_ `
                        -Body $RequestBody

                    if ($Response.StatusCode -ne 200) {
                        Write-Error -Message $("Cannot create observation search job for $($_)")
                    }
                    else {
                        # if search job is created, then we could get the results, but
                        # it is async request so to keep checking, till all are available
                        $JsonContent = $Response.Content | ConvertFrom-Json
                        # get the job_id to retrieve the results for this job
                        $JobId = $JsonContent.job_id
                        $Contacted = -1
                        $Completed = -2
                        $TimeOut = 0
                        $TimeOutFlag = false

                        # if contacted and completed are equal, this means we could get the results
                        while ($Contacted -ne $Completed) {
                            # sleep 0.5 to give it time to retrieve the results - it might still not be enough,
                            # so keep checking for 3 mins before timeout
                            $TimeOut += 0.5
                            Start-Sleep -Seconds 0.5
                            if ($TimeOut -gt 180) {
                                $TimeOutFlag = true
                                Write-Error -Message $("Cannot retrieve observations due to timeout for $($_)")
                                break
                            }

                            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Observations"]["Results"] `
                                -Method GET `
                                -Server $_ `
                                -Params @($JobId, "?start=0&rows=0")

                            $JsonContent = $Response.Content | ConvertFrom-Json
                            $Contacted = $JsonContent.contacted
                            $Completed = $JsonContent.completed
                        }

                        # if we did not fail due to timeout, then we could get the results
                        if (!$TimeOutFlag) {
                            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Observations"]["Results"] `
                                -Method GET `
                                -Server $_ `
                                -Params @($JobId, "?start=0&rows=" + $MaxResults)
                            $JsonContent = $Response.Content | ConvertFrom-Json

                            $JsonContent.results | ForEach-Object {
                                return Initialize-CbcObservation $_ $CurrentServer
                            }
                        }
                    }
                } 
            }
        }
    }
}