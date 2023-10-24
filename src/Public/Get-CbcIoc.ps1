using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all ioc in a specific report from all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet returns all ioc in a specific report from all valid connections.
.PARAMETER FeedId
Id of the Feed
.PARAMETER ReportId
Specify the Id of the report for which to retrieve iocs
.PARAMETER Id
Specify the Id of the ioc to retrieve.
.PARAMETER Report
Specify the CbcReport of the iocs to retrieve.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.OUTPUTS
CbcIoc[]
.NOTES
Permissions needed: READ org.feeds
.EXAMPLE
PS > Get-CbcReport -FeedId 5hBIvXltQqy0oAAqdEh0A, jwUoZu1WRBujSoCcYNa6fA

Returns all reports for specific feed from all connections. 
If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > Get-CbcIoc -FeedId 5hBIvXltQqy0oAAqdEh0A -ReportId 11a1a1a1-b22b-3333-44cc-dd5555d5d5fd -Server $SpecifiedServer

Returns all iocs for specific feed and report.
.EXAMPLE
PS > $report = Get-CbcReport -Id 11a1a1a1-b22b-3333-44cc-dd5555d5d5fd
PS > Get-CbcIoc -Report $report

Returns all iocs for specific report.
#>

function Get-CbcIoc {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcIoc[]])]
    param(
        [Parameter(ParameterSetName = "Default", Position = 0, Mandatory = $true)]
        [string]$FeedId,

        [Parameter(ParameterSetName = "Default", Position = 1, Mandatory = $true)]
        [string]$ReportId,

        [Parameter(ParameterSetName = "Report", Position = 0, Mandatory = $true)]
        [CbcReport]$Report,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Report")]
        [string]$Id,

        [Parameter(ParameterSetName = "Default")]
        [CbcServer[]]$Server
    )

    process {
        if ($Server) {
            $ExecuteServers = $Server
        }
        else {
            $ExecuteServers = $global:DefaultCbcServers
        }
        switch ($PSCmdlet.ParameterSetName) {
            "Default" {
                $ExecuteServers | ForEach-Object {
                    $CurrentServer = $_
                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                        -Method GET `
                        -Server $_ `
                        -Params @($FeedId, $ReportId) `

                    if ($Response.StatusCode -ne 200) {
                        Write-Error -Message $("Cannot get iocs for $($_)")
                    }
                    else {
                        $JsonContent = $Response.Content | ConvertFrom-Json
                        $JsonContent.report.iocs_v2 | ForEach-Object {
                            if ($PSBoundParameters.ContainsKey("Id")) {
                                if ($_.id -eq $Id) {
                                    return Initialize-CbcIoc $_ $CurrentServer
                                }
                            }
                            else {
                                return Initialize-CbcIoc $_ $CurrentServer
                            }
                        }
                        
                    }
                }
            }
            "Report" {
                $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                        -Method GET `
                        -Server $Report.Server `
                        -Params @($Report.FeedId, $Report.Id) `

                if ($Response.StatusCode -ne 200) {
                    Write-Error -Message $("Cannot get iocs for $($_)")
                }
                else {
                    $JsonContent = $Response.Content | ConvertFrom-Json
                    $JsonContent.report.iocs_v2 | ForEach-Object {
                        if ($PSBoundParameters.ContainsKey("Id")) {
                            if ($_.id -eq $Id) {
                                return Initialize-CbcIoc $_ $Report.Server
                            }
                        }
                        else {
                            return Initialize-CbcIoc $_ $Report.Server
                        }
                    }
                    
                }
            }
        }
    }
}