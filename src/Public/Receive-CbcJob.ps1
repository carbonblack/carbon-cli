using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns results of a async job for a cmdlet that was started as -AsJob. Once the job status is Completed, results
can be retrieved, before that the cmdlet will log an error stating that the results are not ready to be retrieved.
.PARAMETER Id
Sets the job id
.OUTPUTS
CbcObservation[] or CbcObservationDetails[] depending on the job type
.EXAMPLE
PS > $criteria = @{"alert_category" = @("THREAT")}
PS > $job = Get-CbcObservation -Include $Criteria -AsJob
PS > $job_status = Get-CbcJob -Job $job
PS > if ($job_status.Status -eq "Completed") {
>> Receive-CbcJob -Job $job
>> }

First operation that is asynchronous should be started as job, which is not going to wait till the completion of the operation,
but will immediately return CbcJob object based on the started operation. After that the status could be checked with the
Get-CbcJob cmdlet. Once the status of the job is determed as completed, then the results can be retrieved with Receive-CbcJob cmdlet.
Currently we support observation_details and observation_search type of jobs.

PS > Receive-CbcJob -Id "id" -Type "observation_details"

Returns the results of a async job.
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/observations-api
#>

function Receive-CbcJob {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(ValueFromPipeline = $true,
            Mandatory = $true,
            Position = 0,
            ParameterSetName = "Default")]
        [CbcJob[]]$Job,

        [Parameter(ValueFromPipeline = $true,
            Mandatory = $true,
            Position = 0,
            ParameterSetName = "Id")]
        [string[]]$Id,

        [Parameter(ValueFromPipeline = $true,
            Mandatory = $true,
            Position = 1,
            ParameterSetName = "Id")]
        [string]$Type,

        [Parameter(ParameterSetName = "Id")]
        [CbcServer[]]$Server
    )
    
    begin {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] function started"
    }
    process {
        if ($Server) {
            $ExecuteServers = $Server
        }
        else {
            $ExecuteServers = $global:DefaultCbcServers
        }

        switch ($PSCmdlet.ParameterSetName) {
            "Default" {
                $JobsList = @($Job)
            }
            "Id" {
                $JobsList = @()
                $Ids = @($Id)
                $Ids | ForEach-Object {
                    $CurrentId = $_
                    $ExecuteServers | ForEach-Object {
                        $JobsList += Initialize-CbcJob $CurrentId $Type "Running" $_
                    }
                }
            }
        }

        $Endpoint = $null
        $JobsList | ForEach-Object {
            $CurrentServer = $_.Server
            $CurrentType = $_.Type
            switch ($CurrentType) {
                "observation_search" {
                    $Endpoint = $global:CBC_CONFIG.endpoints["Observations"]
                }
                "observation_details" {
                    $Endpoint = $global:CBC_CONFIG.endpoints["ObservationDetails"]
                }
            }
            
            if ($Endpoint) {
                $Response = Invoke-CbcRequest -Endpoint $Endpoint["Results"] `
                    -Method GET `
                    -Server $_.Server `
                    -Params @($_.Id, "?start=0&rows=500")

                if ($Response.StatusCode -ne 200) {
                    Write-Error -Message $("Cannot complete action for $($_.Id) for $($_.Server)")
                }
                else {
                    $JsonContent = $Response.Content | ConvertFrom-Json
                    $Contacted = $JsonContent.contacted
                    $Completed = $JsonContent.completed
                    
                    if ($Contacted -ne $Completed) {
                        Write-Error "Not ready to retrieve."
                    }
                    else {
                        $JsonContent.results | ForEach-Object {
                            $Result = $_
                            switch ($CurrentType) {
                                "observation_search" {
                                    return Initialize-CbcObservation $Result $CurrentServer
                                }
                                "observation_details" {
                                    return Initialize-CbcObservation $Result $CurrentServer
                                }
                            }
                        }
                    }
                }
            }
            else {
                Write-Error "Not a valid type $($CurrentType)"
            }
        }
    }
}
