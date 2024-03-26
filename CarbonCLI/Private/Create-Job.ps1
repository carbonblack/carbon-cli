using module ../CarbonCLI.Classes.psm1

function Create-Job {
    param(
		[Parameter(Mandatory = $true,Position = 0)]
		[ValidateNotNullOrEmpty()]
		[hashtable]$Endpoint,

        [Parameter(Mandatory = $true,Position = 1)]
		[ValidateNotNullOrEmpty()]
		[hashtable]$RequestBody,

        [Parameter(Mandatory = $true,Position = 2)]
		[ValidateNotNullOrEmpty()]
		[string]$Type,

        [Parameter(Mandatory = $true,Position = 3)]
		[ValidateNotNullOrEmpty()]
		[CbcServer]$Server
	)
    $JsonBody = $RequestBody | ConvertTo-Json
    $Response = Invoke-CbcRequest -Endpoint $Endpoint["StartJob"] `
        -Method POST `
        -Server $Server `
        -Body $JsonBody

    if ($Response.StatusCode -ne 200) {
        Write-Error -Message $("Cannot create $($Type) job for $($Server)")
    }
    else {
        $JsonContent = $Response.Content | ConvertFrom-Json

        # if started as job, do not wait for the results to be ready
        if ($AsJob) {
            return Initialize-CbcJob $JsonContent.job_id $Type "Running" $Server
        }

        # if details job is created, then we could get the results, but
        # it is async request so to keep checking, till all are available
        $TimeOut = 0
        $TimeOutFlag = false
        $job = Initialize-CbcJob $JsonContent.job_id $Type "Running" $Server
        while ($job.Status -eq "Running") {
            # sleep 0.5 to give it time to retrieve the results - it might still not be enough,
            # so keep checking for 3 mins before timeout
            $TimeOut += 0.5
            Start-Sleep -Seconds 0.5
            if ($TimeOut -gt 180) {
                $TimeOutFlag = true
                Write-Error -Message $("Cannot retrieve observations due to timeout for $($Server)")
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