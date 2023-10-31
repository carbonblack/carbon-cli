using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet creates a report in all valid connections - up to 10K reports can be added in a single feed.

A report groups one or more IOCs together, which may reflect a number of possible conditions to look for, or a number
of conditions related to a particular target program or type of malware. Reports can be used to organize IOCs.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
Watchlists are powerful feature that allows organization to focus on specific rules, for which alerts to be created.
However to take advantage of that functionality, an organization needs to have EEDR product enabled and do execute a flow that creates the 
necessary objects.

The steps to do that are:
1. Create a feed - a feed contains reports which have been gathered by a single source. They resemble “potential watchlists.”
A watchlist may be easily subscribed to a feed, so that any reports in the feed act as if they were in the watchlist itself,
triggering logs or alerts as appropriate.

PS > $Feed = New-CbcFeed -Name myfeed -ProviderUrl http://test.test/ -Summary summary -Category category -Alertable $true

2. Create one or multiple reports - A report groups one or more IOCs together, which may reflect a number of possible conditions
to look for, or a number of conditions related to a particular target program or type of malware. Reports can be used to organize IOCs.

PS > $Report = New-CbcReport -FeedId $Feed.Id -Title myreport -Description description -Severity 5

3. Create IOCs - an indicator of compromise (IOC) is a query, list of strings, or list of regular expressions which constitutes
actionable threat intelligence that the Carbon Black Cloud is set up to watch for. Any activity that matches one of these may
indicate a compromise of an endpoint.

PS > $IocBody = @{"match_type" = "equality"
>>                "values" = @("SHA256HashOfAProcess")
>>                "field" = "process_sha256"}
PS > $Ioc = New-CbcIoc -FeedId $Feed.Id -ReportId $Report.Id -Body $IocBody
PS > $Ioc1 = New-CbcIoc -Report $Report -Body $IocBody

4. Create watchlist (subscribe to the created feed (steps 1 - 3)) - a watchlist contains reports (either directly or through a feed)
that the Carbon Black Cloud is matching against events coming from the endpoints. A positive match will trigger a "hit",
which may be logged or result in an alert.

PS > $Watchlist = New-CbcWatchlist -Feed $feed

At any moment you can get / add / delete / update feeds, reports, iocs and watchlists through the New-* Remove-* or Set-* cmdlets for each object.
.PARAMETER FeedId
Id of the Feed to which this report will be added.
.PARAMETER Feed
CbcFeed object to which this report will be added.
.PARAMETER Title
Title of the Report
.PARAMETER Description
Description of the Report
.PARAMETER Severity
Severity of the Report
.PARAMETER Body
Full request body for the creation of the report (either Title, Description and Severity or Body needs to be provided).
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.OUTPUTS
CbcReport[]
.NOTES
Permissions needed: CREATE org.feeds
.EXAMPLE
PS > New-CbcReport -FeedId JuXVurDTFmszw93it0Gvw -Title myreport -Description description -Severity 5

If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > New-CbcReport -FeedId JuXVurDTFmszw93it0Gvw -Title myreport -Description description -Severity 5 -Server $SpecifiedServer
.EXAMPLE
PS > $reportBody = @{
>>        "title" = "myreport"
>>        "description" = "description"
>>        "severity" = 5
}
PS > New-CbcReport -FeedId JuXVurDTFmszw93it0Gvw -Body $reportBody

Creating report with custom body.
#>

function New-CbcReport {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcReport[]])]
    param(
        [Parameter(ParameterSetName = "CustomBody")]
        [Parameter(ParameterSetName = "Default", Position = 0, Mandatory = $true)]
        [string]$FeedId,

        [Parameter(ParameterSetName = "CustomBody")]
        [Parameter(ParameterSetName = "Feed", Position = 0, Mandatory = $true)]
        [CbcFeed]$Feed,

        [Parameter(ParameterSetName = "Feed", Mandatory = $true)]
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$Title,

        [Parameter(ParameterSetName = "Feed", Mandatory = $true)]
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$Description,

        [Parameter(ParameterSetName = "Feed", Mandatory = $true)]
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [int]$Severity,

        [Parameter(ParameterSetName = "CustomBody", Mandatory = $true)]
        [hashtable]$Body,

        [Parameter(ParameterSetName = "CustomBody")]
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

        if ($PSBoundParameters.ContainsKey("FeedId")) {
            $ExecuteServers | ForEach-Object {
                $FeedDetails = Get-CbcFeedDetails -Id $FeedId -Server $_
                if ($FeedDetails.Reports.Count -ge 10000) {
                    Write-Error "Cannot add more reports to that feed."
                }
                else {
                    $RequestBody = @{}
                    $RequestBody.reports = @()
                    if ($FeedDetails.Reports) {
                        $RequestBody.reports = $FeedDetails.Reports
                    }
                    if ($PSBoundParameters.ContainsKey("Body")) {
                        $NewReport = $Body.Clone()
                        if (!$NewReport.ContainsKey("id")) {
                            $NewReport.id = [string](New-Guid)
                        }
                        $NewReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                        $RequestBody.reports += $NewReport
                    }
                    else {
                        $NewReport = @{}
                        $NewReport.title = $Title
                        $NewReport.description = $Description
                        $NewReport.severity = $Severity
                        $NewReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                        $NewReport.id = [string](New-Guid)
                        $RequestBody.reports += $NewReport
                    }

                    $RequestBody = $RequestBody | ConvertTo-Json -Depth 100
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
        elseif ($PSBoundParameters.ContainsKey("Feed")) {
            $FeedDetails = Get-CbcFeedDetails -Feed $Feed
            $RequestBody = @{}
            $RequestBody.reports = @()
            if ($FeedDetails.Reports) {
                $RequestBody.reports = $FeedDetails.Reports
            }

            if ($RequestBody.reports.Count -ge 10000) {
                Write-Error "Cannot add more reports to that feed."
            }
            else {
                if ($PSBoundParameters.ContainsKey("Body")) {
                    $NewReport = $Body.Clone()
                    if (!$NewReport.ContainsKey("id")) {
                        $NewReport.id = [string](New-Guid)
                    }
                    $NewReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                    $RequestBody.reports += $NewReport
                }
                else {
                    $NewReport = @{}
                    $NewReport.title = $Title
                    $NewReport.description = $Description
                    $NewReport.severity = $Severity
                    $NewReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                    $NewReport.id = [string](New-Guid)
                    $RequestBody.reports += $NewReport
                }

                $RequestBody = $RequestBody | ConvertTo-Json -Depth 100

                $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Search"] `
                    -Method POST `
                    -Server $Feed.Server `
                    -Params $Feed.Id `
                    -Body $RequestBody

                if ($Response.StatusCode -ne 200) {
                    Write-Error -Message $("Cannot update reports for $($Feed.Server)")
                }
                else {
                    return Get-CbcReport -Feed $Feed -Id $NewReport.id
                }
            }
        }
    }
}