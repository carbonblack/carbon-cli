using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns processes.
.PARAMETER Id
Returns the processes with the specified process guids.
.PARAMETER Process
Returns the process details based on a CbcProcess object
.OUTPUTS
CbcProcessDetails[]
.NOTES
Permissions needed: CREATE, READ org.search.events
.EXAMPLE
PS > Get-CbcProcessDetails -Id "95016925089911ee9568b74cff311:23f4c71a-e350-8576-f832-0b0968f"

Returns the processes with specified Ids.
.EXAMPLE
PS > $criteria = @{"device_name" = @("Win7x64")} 
PS > Get-CbcProcess -Include $criteria | Get-CbcProcessDetails

Returns the process details for all processes that matches the criteria.
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/platform-search-api-processes
#>

function Get-CbcProcessDetails {
    [CmdletBinding(DefaultParameterSetName = "Id")]
    [OutputType([CbcProcessDetails[]])]
    param(
        [Parameter(ParameterSetName = "Id", Position = 0)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Id")]
        [CbcServer[]]$Server,

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "Process")]
        [switch]$AsJob,

        [Parameter(ValueFromPipeline = $true,
			Mandatory = $true,
			Position = 0,
			ParameterSetName = "Process")]
		[CbcProcess[]]$Process
    )

    process {
        if ($Server) {
            $ExecuteServers = $Server
        }
        else {
            $ExecuteServers = $global:DefaultCbcServers
        }
        $Endpoint = $global:CBC_CONFIG.endpoints["ProcessDetails"]

        if ($PSCmdlet.ParameterSetName -eq "Id") {
            $ExecuteServers | ForEach-Object {
                $RequestBody = @{}
                $RequestBody.process_guids = @($Id)
                return Create-Job $Endpoint $RequestBody "process_details" $_
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq "Process") {
            $ProcessGroups = $Process | Group-Object -Property Server
            foreach ($Group in $ProcessGroups) {
                $RequestBody = @{}
                $RequestBody.process_guids = @()
                foreach ($CurrProcess in $Group.Group) {
                    $RequestBody.process_guids += $CurrProcess.Id
                    $CurrentServer = $CurrProcess.Server
                }
                return Create-Job $Endpoint $RequestBody "process_details" $CurrentServer
            }
        }
    }
}
