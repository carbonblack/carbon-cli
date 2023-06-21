using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns results of a observation job for async operation.
.PARAMETER Id
Sets the job id
.OUTPUTS
CbcObservation[]
.EXAMPLE
PS > Receive-CbcObservationJob -Id "id" -Type "observation_details"

Returns the results of a async job.
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/observations-api
#>

function Receive-CbcObservationJob {
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

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "Default")]
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
                        $JobsList += Initialize-CbcJob $CurrentId "observation" $_
                    }
                }
            }
        }

        $Jobs = @()
        $Endpoint = $global:CBC_CONFIG.endpoints["Observation"]
        $Results = @()
        $JobsList | ForEach-Object {
            $CurrentServer = $_.Server
            $Response = Invoke-CbcRequest -Endpoint $Endpoint["Results"] `
                    -Method GET `
                    -Server $_.Server `
                    -Params @($_.Id, "?start=0&rows=500")

            if ($Response.StatusCode -ne 200) {
                Write-Error -Message $("Cannot complete action for $($_.Server)")
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
                        $Results += Initialize-CbcObservation $_ $CurrentServer
                    }
                }
            }
        }
        return $Results
    }
}
