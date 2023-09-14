using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet creates a report in all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet creates a report in all valid connections.
.PARAMETER FeedId
Id of the Feed to which this report will be added (required)
.PARAMETER Title
Title of the Report (required)
.PARAMETER Description
Description of the Report (required)
.PARAMETER Severity
Severity of the Report (required)
.OUTPUTS
CbcReport
.NOTES
Permissions needed: CREATE org.feeds
.EXAMPLE
PS > New-CbcReport -FeedId JuXVurDTFmszw93it0Gvw -Title myreport -Description description -Severity 5

If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > New-CbcReport -FeedId JuXVurDTFmszw93it0Gvw -Title myreport -Description description -Severity 5 -Server $SpecifiedServer
.EXAMPLE
#>

function New-CbcReport {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcReport])]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$FeedId,

        [Parameter(ParameterSetName = "Feed", Mandatory = $true)]
        [CbcFeed]$Feed,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$Title,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$Description,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
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
       
        $ExecuteServers | ForEach-Object {
            $CurrentServer = $_
            $Feed = Get-CbcFeed -Id $FeedId -Server $_
            $RequestBody = @{}
            # TODO - get the reports from the feed and ADD the new report
            $NewReport = @{}
            $NewReport.title = $Title
            $NewReport.description = $Description
            $NewReport.severity = $Severity
            $NewReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
            $NewReport.id = [string](New-Guid)
            $RequestBody.reports = @()
            $RequestBody.reports += $Feed.RawReports
            $RequestBody.reports += $NewReport

            $RequestBody = $RequestBody | ConvertTo-Json

            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Search"] `
                -Method POST `
                -Server $_ `
                -Params $FeedId `
                -Body $RequestBody

            if ($Response.StatusCode -ne 200) {
                Write-Error -Message $("Cannot update reports for $($_)")
            }
            else {
                return Get-CbcReport -FeedId $FeedId -Id $NewReport.id
            }
        }
    }
}