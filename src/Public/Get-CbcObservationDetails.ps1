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
.NOTES
Permissions needed: READ, CREATE org.search.events
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
        [Parameter(ParameterSetName = "Alert")]
        [Parameter(ParameterSetName = "Observation")]
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
		[CbcAlert[]]$Alert
    )

    process {
        if ($Server) {
            $ExecuteServers = $Server
        }
        else {
            $ExecuteServers = $global:DefaultCbcServers
        }
        $Endpoint = $global:CBC_CONFIG.endpoints["ObservationDetails"]

        if ($PSCmdlet.ParameterSetName -eq "Id" -or $PSCmdlet.ParameterSetName -eq "AlertId") {
            $ExecuteServers | ForEach-Object {
                $RequestBody = @{}
                switch ($PSCmdlet.ParameterSetName) {
                    "Id" {
                        $RequestBody.observation_ids = $Id
                    }
                    "AlertId" {
                        $RequestBody.alert_id = $AlertId
                    }
                }
                return Create-Job $Endpoint $RequestBody "observation_details" $_
            }
        }
        else {
            switch ($PSCmdlet.ParameterSetName) {
                "Alert" {
                    $Alert | ForEach-Object {
                        # only one alert could be sent in the body, so do not group
                        $RequestBody = @{}
                        $RequestBody.alert_id = $Alert.Id
                        return Create-Job $Endpoint $RequestBody "observation_details" $Alert.Server
                    }
                }
                "Observation" {
                    $ObservationGroups = $Observation | Group-Object -Property Server
                    foreach ($Group in $ObservationGroups) {
                        $RequestBody = @{}
                        $RequestBody.observation_ids = @()
                        foreach ($CurrObservation in $Group.Group) {
                            $RequestBody.observation_ids += $CurrObservation.Id
                            $CurrentServer = $CurrObservation.Server
            			}
                        return Create-Job $Endpoint $RequestBody "observation_details" $CurrentServer
                    }
                }
            }
        }
    }
}
