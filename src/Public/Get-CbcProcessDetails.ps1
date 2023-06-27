using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns processes.
.PARAMETER Id
Returns the processes with the specified process guids.
.OUTPUTS
CbcProcess[]
.EXAMPLE
PS > Get-CbcProcessDetails -Id "95016925089911ee9568b74cff311:23f4c71a-e350-8576-f832-0b0968f"

Returns the processes with specified Ids.
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/platform-search-api-processes
#>

function Get-CbcProcessDetails {
    [CmdletBinding(DefaultParameterSetName = "Id")]
    [OutputType([CbcProcess[]])]
    param(
        [Parameter(ParameterSetName = "Id", Position = 0)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "AlertId")]
        [CbcServer[]]$Server,

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "AlertId")]
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
            $Endpoint = $global:CBC_CONFIG.endpoints["ProcessDetails"]
            $RequestBody = @{}

            switch ($PSCmdlet.ParameterSetName) {
                "Id" {
                    $RequestBody.process_guids = $Id
                }
            }

            $RequestBody = $RequestBody | ConvertTo-Json
            $Response = Invoke-CbcRequest -Endpoint $Endpoint["StartJob"] `
                -Method POST `
                -Server $_ `
                -Body $RequestBody

            if ($Response.StatusCode -ne 200) {
                Write-Error -Message $("Cannot create process details job for $($_)")
            }
            else {
                $JsonContent = $Response.Content | ConvertFrom-Json

                # if started as job, do not wait for the results to be ready
                if ($AsJob) {
                    return Initialize-CbcJob $JsonContent.job_id "process_details" "Running" $_
                }

                # if details job is created, then we could get the results, but
                # it is async request so to keep checking, till all are available
                $TimeOut = 0
                $TimeOutFlag = false
                $job = Initialize-CbcJob $JsonContent.job_id "process_details" "Running" $_
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
