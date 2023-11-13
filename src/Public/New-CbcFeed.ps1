using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet creates a feed in all valid connections.

A feed contains reports which have been gathered by a single source. They resemble “potential watchlists.”
A watchlist may be easily subscribed to a feed, so that any reports in the feed act as if they were in the watchlist itself
triggering logs or alerts as appropriate.

.LINK  
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
Watchlists are powerful feature that allows organization to focus on specific rules, for which alerts to be created.
However to take advantage of that functionality, an organization needs to have EEDR product enabled and do execute a flow that creates the 
necessary objects.

The steps to do that are:
1. Create a feed - a feed contains reports which have been gathered by a single source. They resemble "potential watchlists."
A watchlist may be easily subscribed to a feed, so that any reports in the feed act as if they were in the watchlist itself,
triggering logs or alerts as appropriate.

PS > $Feed = New-CbcFeed -Name myfeed -ProviderUrl http://test.test/ -Summary summary -Category category -Alertable $true

2. Create one or multiple reports - a report groups one or more IOCs together, which may reflect a number of possible conditions
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
.PARAMETER Name
Name of the Feed (required)
.PARAMETER ProviderUrl
Provider URL of the Feed (required). Should be a valid url string.
.PARAMETER Summary
Summary of the Feed (required). Custom summary provided by the user.
.PARAMETER Category
Category of the Feed (required). Custom category provided by the user.
.PARAMETER Alertable
Optional indicator whether you would like to be alerted for IOCs included in the Feed. Provide $false to supress noisy feeds.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.OUTPUTS
CbcFeedDetails[]
.NOTES
Permissions needed: CREATE org.feeds
.EXAMPLE
PS > New-CbcFeed -Name myfeed -ProviderUrl http://test.test/ -Summary summary -Category category -Alertable $true

If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > New-CbcFeed -Name myfeed -ProviderUrl http://test.test/ -Summary summary -Category category -Alertable $true -Server $SpecifiedServer
.EXAMPLE
PS > $CustomBody = @{"feedinfo" =
>>                    @{"name"= "myfeed"
>>                      "provider_url"  = "http://test.test/"
>>                      "summary" = "summary"
>>                      "category" = "category" 
>>                      "alertable" = $true}
>>                   "reports"= @()}
PS > New-CbcFeed -Body $CustomBody

Create a feed by providing the full request body - feedinfo and reports.
#>

function New-CbcFeed {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcFeed[]])]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$Name,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$ProviderUrl,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$Summary,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$Category,

        [Parameter(ParameterSetName = "Default")]
        [bool]$Alertable,

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
       
        $ExecuteServers | ForEach-Object {
            $CurrentServer = $_
            if ($PSCmdlet.ParameterSetName -eq "Default") {
                $RequestBody = @{}
                $RequestBody.feedinfo = @{}
                $RequestBody.reports = @()
                $RequestBody.feedinfo.name = $Name
                $RequestBody.feedinfo.provider_url = $ProviderUrl
                $RequestBody.feedinfo.summary = $Summary
                $RequestBody.feedinfo.category = $Category
                if ($PSBoundParameters.ContainsKey("Alertable")) {
                    $RequestBody.feedinfo.alertable = $Alertable
                }
            }
            else {
                $RequestBody = $Body
            }
            $RequestBody = $RequestBody | ConvertTo-Json

            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Feed"]["Search"] `
                -Method POST `
                -Server $_ `
                -Body $RequestBody

            if ($Response.StatusCode -ne 200) {
                Write-Error -Message $("Cannot create feed for $($_)")
            }
            else {
                $JsonContent = $Response.Content | ConvertFrom-Json
                return Initialize-CbcFeed $JsonContent $CurrentServer
            }
        }
    }
}