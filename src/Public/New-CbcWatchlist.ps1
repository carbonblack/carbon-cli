using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet subscribes to feed in all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
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
.PARAMETER FeedId
FeedId to which to subscribe.
.PARAMETER Feed
CbcFeed to which to subscribe.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.OUTPUTS
CbcWatchlist
.NOTES
Permissions needed: CREATE org.watchlists
.EXAMPLE
PS > $Feed = Get-CbcFeed -Id JuXVurDTFmszw93it0Gvw
PS > New-CbcWatchlist -Feed $Feed

PS > New-CbcWatchlist -Feed (Get-CbcFeed -Id JuXVurDTFmszw93it0Gvw)
.EXAMPLE
PS > New-CbcWatchlist -FeedId JuXVurDTFmszw93it0Gvw

If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > New-CbcWatchlist -FeedId JuXVurDTFmszw93it0Gvw -Server $SpecificServer
#>

function New-CbcWatchlist {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcFeed])]
    param(
        [Parameter(ParameterSetName = "Default", Position = 0, Mandatory = $true)]
        [string]$FeedId,

        [Parameter(ParameterSetName = "Feed", Position = 0, Mandatory = $true)]
        [CbcFeed]$Feed,

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
                    $Feed = Get-CbcFeed -Id $FeedId -Server $CurrentServer
                    $RequestBody = @{}
                    $RequestBody.name = $Feed.Name
                    $RequestBody.description = $Feed.Summary
                    $RequestBody.alerts_enabled = $Feed.Alertable
                    $RequestBody.classifier = @{
                        "key"   = "feed_id"
                        "value" = $Feed.Id
                    }
                    
                    $RequestBody = $RequestBody | ConvertTo-Json

                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Feed"]["Subscribe"] `
                        -Method POST `
                        -Server $_ `
                        -Body $RequestBody

                    if ($Response.StatusCode -ne 200) {
                        Write-Error -Message $("Cannot subscribe to feed for $($_)")
                    }
                    else {
                        $JsonContent = $Response.Content | ConvertFrom-Json
                        return Initialize-CbcWatchlist $JsonContent $CurrentServer $Feed.Id
                    }
                }
            }
            "Feed" {
                $RequestBody = @{}
                $RequestBody.name = $Feed.Name
                $RequestBody.description = $Feed.Summary
                $RequestBody.alerts_enabled = $Feed.Alertable
                $RequestBody.classifier = @{
                    "key"   = "feed_id"
                    "value" = $Feed.Id
                }
                
                $RequestBody = $RequestBody | ConvertTo-Json

                $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Feed"]["Subscribe"] `
                    -Method POST `
                    -Server $Feed.Server `
                    -Body $RequestBody

                if ($Response.StatusCode -ne 200) {
                    Write-Error -Message $("Cannot subscribe to feed for $($Feed.Server)")
                }
                else {
                    $JsonContent = $Response.Content | ConvertFrom-Json
                    return Initialize-CbcWatchlist $JsonContent $Feed.Server $Feed.Id
                }
                
            }
        }
    }
}