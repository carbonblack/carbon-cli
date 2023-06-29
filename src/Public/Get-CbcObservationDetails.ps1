using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns an observation details.
.PARAMETER Id
Returns the observation details with the specified Ids.
.PARAMETER AlertId
Returns the observation details with the specified Alert Id.
.PARAMETER Alert
Returns the observation details for the specified CbcAlert.
.PARAMETER Observation
Returns the observation details for the specified CbcObservation.
.OUTPUTS
CbcObservationDetails[]
.EXAMPLE
PS > Get-CbcObservationDetails -Id "95016925089911ee9568b74cff311:23f4c71a-e350-8576-f832-0b0968f"

Returns the observations with specified Ids.
.EXAMPLE
PS > Get-CbcObservationDetails -AlertId "11a1a1a1-b22b-3333-44cc-dd5555d5d55d"

Returns the observations with that AlertId
.EXAMPLE
PS > Get-CbcAlert -Id "982e5f1c-e893-5914-cea9-3478f88e9ef1" | Get-CbcObservationDetails

Returns the observation details with that Alert
.EXAMPLE
PS > Get-CbcObservation -Include @{"alert_category" = @("THREAT")} | Get-CbcObservationDetails

Returning all the observation details that are for observations in the THREAT alert category.
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/observations-api
#>

function Get-CbcObservationDetails {
    [CmdletBinding(DefaultParameterSetName = "Id")]
    [OutputType([CbcObservationDetails[]])]
    param(
        [Parameter(ParameterSetName = "Id", Position = 0)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "AlertId", Position = 0)]
        [string]$AlertId,

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "AlertId")]
        [CbcServer[]]$Server,

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "AlertId")]
        [switch]$AsJob,

        [Parameter(ValueFromPipeline = $true,
			Mandatory = $true,
			Position = 0,
			ParameterSetName = "Observation")]
		[CbcObservation[]]$Observation,

        [Parameter(ValueFromPipeline = $true,
			Mandatory = $true,
			Position = 0,
			ParameterSetName = "Alert")]
		[CbcAlert]$Alert
    )

    process {
        if ($Server) {
            $ExecuteServers = $Server
        }
        else {
            $ExecuteServers = $global:DefaultCbcServers
        }

        $ExecuteServers | ForEach-Object {
            $Endpoint = $global:CBC_CONFIG.endpoints["ObservationDetails"]
            $RequestBody = @{}
            switch ($PSCmdlet.ParameterSetName) {
                "Id" {
                    $RequestBody.observation_ids = $Id
                }
                "AlertId" {
                    $RequestBody.alert_id = $AlertId
                }
                "Alert" {
                    $RequestBody.alert_id = $Alert.Id
                }
                "Observation" {
                    $Ids = $Observation | ForEach-Object {
					    $_.ObservationId
				    }
                    $RequestBody.observation_ids = @($Ids)
                }
            }

            $RequestBody = $RequestBody | ConvertTo-Json
            $Response = Invoke-CbcRequest -Endpoint $Endpoint["StartJob"] `
                -Method POST `
                -Server $_ `
                -Body $RequestBody

            if ($Response.StatusCode -ne 200) {
                Write-Error -Message $("Cannot create observation details job for $($_)")
            }
            else {
                $JsonContent = $Response.Content | ConvertFrom-Json

                # if started as job, do not wait for the results to be ready
                if ($AsJob) {
                    return Initialize-CbcJob $JsonContent.job_id "observation_details" "Running" $_
                }

                # if details job is created, then we could get the results, but
                # it is async request so to keep checking, till all are available
                $TimeOut = 0
                $TimeOutFlag = false
                $job = Initialize-CbcJob $JsonContent.job_id "observation_details" "Running" $_
                while ($job.Status -eq "Running") {
                    # sleep 0.5 to give it time to retrieve the results - it might still not be enough,
                    # so keep checking for 3 mins before timeout
                    $TimeOut += 0.5
                    Start-Sleep -Seconds 0.5
                    if ($TimeOut -gt 180) {
                        $TimeOutFlag = true
                        Write-Error -Message $("Cannot retrieve observations due to timeout for $($_)")
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
