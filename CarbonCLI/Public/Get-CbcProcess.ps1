using module ../CarbonCLI.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all processes from all valid connections. The retrieval of process includes two API requests
first to start a job with specific criteria/query. The second one is getting the results based on the job that was created.
The second API request is asynchronous, so we need to make sure all of the results are available, before returning the results.
.PARAMETER Exclude
Sets the exclusions for the search. Either query or criteria/exclusions must be included.
.PARAMETER Id
Returns the process with the specified Ids.
.PARAMETER Include
Sets the criteria for the search. Either query or criteria/exclusions must be included.
.PARAMETER MaxResults
Set the max number of results (default is 500 and max is 10k).
.PARAMETER Query
Set the query - query is in lucene syntax and/or including value searches. Either query or criteria/exclusions must be included.
.OUTPUTS
CbcProcess[]
.NOTES
Permissions needed: CREATE, READ org.search.events
.EXAMPLE
PS > Get-CbcProcess -Id "95016925089911ee9568b74cff311:23f4c71a-e350-8576-f832-0b0968f", "95016925089911ee9568b74cff311:23f4c71a-e350-8576-f832-0b0968f"

Returns the processes with specified Ids.
.EXAMPLE
PS > $criteria = @{"device_name" = @("Win7x64")}
PS > Get-CbcProcess -Include $Criteria

Returns all processes which correspond to the specified criteria.
.EXAMPLE
PS > Get-CbcProcess -Query "device_name:Win7x64"

Returns all processes which correspond to the specified query.
.EXAMPLE
PS > Get-CbcProcess -ProcessHash "95397c121a7282c3edda11d41615fadf50e172e0c4c3671ad16af9d19411f459" -DeviceId "1212121"

Returns all processes which correspond to the specified query.
.EXAMPLE
PS > $criteria = @{"device_name" = @("Win7x64")}
PS > $job = Get-CbcProcess -Include $Criteria -AsJob
PS > while ($job.Status -eq "Running") {
>> Start-Sleep -Seconds 0.5
>> $job = Get-CbcJob -Job $job
}
$processes = Receive-CbcJob -Job $job

Start a job based on criteria. Then keep checking the status in 0.5 seconds intervals till the status of the job is
Running, the it is safe to retrieve the results.
.LINK
Full list of searchable fields: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/platform-search-fields
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/platform-search-api-processes
#>

function Get-CbcProcess {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcProcess[]])]
    param(
        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Id", Position = 0)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Filter")]
        [string[]]$DeviceId,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Filter")]
        [string[]]$ProcessHash,

        [Parameter(ParameterSetName = "IncludeExclude", Mandatory = $true)]
        [hashtable]$Include,

        [Parameter(ParameterSetName = "IncludeExclude")]
        [hashtable]$Exclude,

        [Parameter(ParameterSetName = "Query")]
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
        [switch]$AsJob
    )

    process {
        if ($Server) {
            $ExecuteServers = $Server
        }
        else {
            $ExecuteServers = $global:DefaultCbcServers
        }

        $ExecuteServers | ForEach-Object {
            $Endpoint = $global:CBC_CONFIG.endpoints["Processes"]
            $RequestBody = @{}
            $RequestBody.rows = $MaxResults
            switch ($PSCmdlet.ParameterSetName) {
                "Default" {
                    $RequestBody.criteria = @{}
                    if ($PSBoundParameters.ContainsKey("Id")) {
                        $RequestBody.criteria.process_guid = $Id
                    }
                    if ($PSBoundParameters.ContainsKey("DeviceId")) {
                        $RequestBody.criteria.device_id = $DeviceId
                    }
                    if ($PSBoundParameters.ContainsKey("ProcessHash")) {
                        $RequestBody.criteria.process_hash = $ProcessHash
                    }
                }
                "IncludeExclude" {
                    $RequestBody.criteria = @{}
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

            $RequestBody = $RequestBody | ConvertTo-Json
            $Response = Invoke-CbcRequest -Endpoint $Endpoint["StartJob"] `
                -Method POST `
                -Server $_ `
                -Body $RequestBody

            if ($Response.StatusCode -ne 200) {
                Write-Error -Message $("Cannot create process search job for $($_)")
            }
            else {
                $JsonContent = $Response.Content | ConvertFrom-Json
                # if started as job, do not wait for the results to be ready
                if ($AsJob) {
                    return Initialize-CbcJob $JsonContent.job_id "process_search" "Running" $_
                }

                # if search job is created, then we could get the results, but
                # it is async request so to keep checking, till all are available
                $TimeOut = 0
                $TimeOutFlag = false
                $job = Initialize-CbcJob $JsonContent.job_id "process_search" "Running" $_
                while ($job.Status -eq "Running") {
                    # sleep 0.5 to give it time to retrieve the results - it might still not be enough,
                    # so keep checking for 3 mins before timeout
                    $TimeOut += 0.5
                    Start-Sleep -Seconds 0.5
                    if ($TimeOut -gt 180) {
                        $TimeOutFlag = true
                        Write-Error -Message $("Cannot retrieve processes due to timeout for $($_)")
                        break
                    }
                    $job = Get-CbcJob -Job $job
                }

                # if we did not fail due to timeout, then we could get the results
                if (!$TimeOutFlag) {
                    Receive-CbcJob -Job $job
                }
            }
        }
    }
}
