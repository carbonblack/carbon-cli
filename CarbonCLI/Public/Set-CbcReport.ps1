using module ../CarbonCLI.Classes.psm1
<#
.DESCRIPTION
This cmdlet updates report for all valid connections.
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet updates report for all valid connections.

A report groups one or more IOCs together, which may reflect a number of possible conditions to look for, or a number
of conditions related to a particular target program or type of malware. Reports can be used to organize IOCs.
.PARAMETER FeedId
Specify the Id of the feed to which the report to be updated belongs.
.PARAMETER Id
Specify the Id of the report to update.
.PARAMETER Report
Specify the CbcReport to update.
.PARAMETER Title
Specify the new title for the report.
.PARAMETER Description
Specify the new description for the report.
.PARAMETER Severity
Specify the new value for severity for the report.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.NOTES
Permissions needed: CREATE, UPDATE org.feeds
.EXAMPLE
PS > Set-CbcReport -FeedId R4cMgFIhRaakgk749MRr6Q -Id R4cMgFIhRaakgk749MRr6Q -Title demo -Severity 6

Update report title and severity with specific ids from all connections.
If you have multiple connections and you want watchlist from a specific connection
you can add the `-Server` param.

PS > Set-CbcReport -FeedId R4cMgFIhRaakgk749MRr6Q -Id R4cMgFIhRaakgk749MRr6Q -Title demo -Severity 6 -Server $SpecifiedServer
.EXAMPLE
PS > $report = Get-CbcReport -FeedId R4cMgFIhRaakgk749MRr6Q -Id R4cMgFIhRaakgk749MRr6Q
PS > Set-CbcReport -Report $report -Title demo

Updates specific watchlists by proving CbcReport.
#>

function Set-CbcReport {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$FeedId,

        [Parameter(ParameterSetName = "Report", Mandatory = $true)]
        [CbcReport[]]$Report,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Report")]
        [string]$Title,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Report")]
        [string]$Description,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Report")]
        [int]$Severity,

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
                    $Id | ForEach-Object {
                        $ReportObj = Get-CbcReport -FeedId $FeedId -Id $_ -Server $CurrentServer
                        return Update-CbcReport $ReportObj $PSBoundParameters
                    }
                }
            }
            "Report" {
                $Report | ForEach-Object {
                    return Update-CbcReport $_ $PSBoundParameters
                }
            }
        }
    }
}