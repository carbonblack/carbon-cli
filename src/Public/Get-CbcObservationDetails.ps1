using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all observations from all valid connections. The retrieval of observation includes two API requests
first to start a job with specific criteria/query. The second one is getting the results based on the job that was created.
The second API request is asynchronous, so we need to make sure all of the results are available, before returning the results.
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
While invoking -Id and -AlertId the cmdlet is requsting the `{cbc-hostname}/api/investigate/v2/orgs/{org_key}/observations/detail_jobs` api,
it is still possible to search by id by providing it into the $criteria param
.EXAMPLE
PS > Get-CbcObservation -Id "95016925089911ee9568b74cff311:23f4c71a-e350-8576-f832-0b0968f"

Returns the observations with specified Ids.
.EXAMPLE
PS > Get-CbcObservation -AlertId "11a1a1a1-b22b-3333-44cc-dd5555d5d55d"

Returns the observations with that AlertId
.EXAMPLE
The criteria for
PS > $criteria = @{"alert_category" = @("THREAT"), "observation_id" = @("11a1a1a1-b22b-3333-44cc-dd5555d5d55a", "11a1a1a1-b22b-3333-44cc-dd5555d5d55b")}
PS > Get-CbcObservation -Include $Criteria

Include parameters expect a hash table object
Returns all alerts which correspond to the specified criteria.
.EXAMPLE
PS > Get-CbcObservation -Include @{"alert_category" = @("THREAT")}

Returning all the observations that are in the THREAT alert category.
.LINK
Full list of searchable fields: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/platform-search-fields
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/observations-api
#>

function Get-CbcObservationDetails {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcObservation[]])]
    param(
        [Parameter(ParameterSetName = "Id", Position = 0)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "AlertId", Position = 0)]
        [string[]]$AlertId,

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

        $ExecuteServers | ForEach-Object {
            $CurrentServer = $_
            $Endpoint = $global:CBC_CONFIG.endpoints["ObservationDetails"]
            $RequestBody = @{}

            switch ($PSCmdlet.ParameterSetName) {
                "Id" {
                    $RequestBody.observation_ids = $Id
                }
                "AlertId" {
                    $RequestBody.alert_id = $AlertId
                }
            }

            $RequestBody = $RequestBody | ConvertTo-Json
            $Response = Invoke-CbcRequest -Endpoint $Endpoint["StartJob"] `
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

                    $Response = Invoke-CbcRequest -Endpoint $Endpoint["Results"] `
                        -Method GET `
                        -Server $_ `
                        -Params @($JobId, "?start=0&rows=0")

                    $JsonContent = $Response.Content | ConvertFrom-Json
                    $Contacted = $JsonContent.contacted
                    $Completed = $JsonContent.completed
                }

                # if we did not fail due to timeout, then we could get the results
                if (!$TimeOutFlag) {
                    $Response = Invoke-CbcRequest -Endpoint $Endpoint["Results"] `
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
