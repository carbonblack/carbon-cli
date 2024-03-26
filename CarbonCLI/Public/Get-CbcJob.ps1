using module ../CarbonCLI.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns the status of a job for async operation - currently supported:
* observation_search
* observation_details
* process_search
* process_details
.PARAMETER Id
Sets the job id
.OUTPUTS
CbcJob[]
.NOTES
Permissions needed: READ, CREATE org.search.events
.EXAMPLE
PS > $criteria = @{"alert_category" = @("THREAT")}
PS > $job = Get-CbcObservation -Include $Criteria -AsJob
PS > $job_status = Get-CbcJob -Job $job
PS > $job_status.Status

First operation that is asynchronous should be started as job, which is not going to wait till the completion of the operation,
but will immediately return CbcJob object based on the started operation. After that the status could be checked with the
Get-CbcJob cmdlet, which can be started either with a job object that contains all the infomation for the job, or by
providing id and type of the job.
Currently we support:
* observation_search
* observation_details
* process_search
* process_details

.EXAMPLE
PS > Get-CbcJob -Id "id1", "id2" -Type "observation_details"

.EXAMPLE
PS > Get-CbcJob -Job $JobObject

Returns the job for specific id.
.LINK
API Documentation Observations: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/observations-api
.LINK
API Documentation Processes: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/platform-search-api-processes
#>

function Get-CbcJob {
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
            switch ($_.Type) {
                "observation_search" {
                    $Endpoint = $global:CBC_CONFIG.endpoints["Observations"]
                }
                "observation_details" {
                    $Endpoint = $global:CBC_CONFIG.endpoints["ObservationDetails"]
                }
                "process_search" {
                    $Endpoint = $global:CBC_CONFIG.endpoints["Processes"]
                }
                "process_details" {
                    $Endpoint = $global:CBC_CONFIG.endpoints["ProcessDetails"]
                }
            }
            if ($Endpoint) {
                $Response = Invoke-CbcRequest -Endpoint $Endpoint["Results"] `
                    -Method GET `
                    -Server $_.Server `
                    -Params @($_.Id, "?start=0&rows=0")

                if ($Response.StatusCode -ne 200) {
                    Write-Error -Message $("Cannot complete action for $($_.Id) for $($_.Server)")
                }
                else {
                    $JsonContent = $Response.Content | ConvertFrom-Json
                    $Contacted = $JsonContent.contacted
                    $Completed = $JsonContent.completed

                    if ($Contacted -ne $Completed) {
                        return Initialize-CbcJob $_.Id $_.Type "Running" $_.Server
                    }
                    else {
                        return Initialize-CbcJob $_.Id $_.Type "Completed" $_.Server
                    }
                }
            }
            else {
                Write-Error "Not a valid type $($Type)"
            }
        }
    }
}
