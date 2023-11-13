using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet is created to add ioc to existing report.

An indicator of compromise (IOC) is a query, list of strings, or list of regular expressions which constitutes
actionable threat intelligence that the Carbon Black Cloud is set up to watch for. Any activity that matches one of these may
indicate a compromise of an endpoint.
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
.PARAMETER FeedId
Id of the FeedId
.PARAMETER ReportId
Id of the ReportId
.PARAMETER Report
CbcReport under which the ioc should be added.
.PARAMETER Body
Hashtable with information about the IOC
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.OUTPUTS
CbcIoc[]
.NOTES
Permissions needed: CREATE org.feeds
.EXAMPLE
PS > $Body = @{"match_type" = "equality"
>>    "field" =  "process_sha256"
>>    "values" = @("SHA256HashOfAProcess")
>>   }
PS > New-CbcIoc -FeedId JuXVurDTFmszw93it0Gvw -ReportId 59ac2095-c663-44cd-99cb-4ce83e7aa894 -Body $Body

If you have multiple connections and you want iocs from a specific connection
you can add the `-Server` param.

PS > New-CbcIoc -FeedId JuXVurDTFmszw93it0Gvw -ReportId 59ac2095-c663-44cd-99cb-4ce83e7aa894 -Body $Body -Server $SpecifiedServer

.EXAMPLE
PS > $Body = @{}
PS > $Body.match_type = "equality"
PS > $Body.field = "process_sha256"
PS > $Body.values = @("SHA256HashOfAProcess")
PS > New-CbcIoc -FeedId JuXVurDTFmszw93it0Gvw -ReportId 59ac2095-c663-44cd-99cb-4ce83e7aa894 -Body $Body

.EXAMPLE
PS > $Feed = Get-CbcFeed -Id JuXVurDTFmszw93it0Gvw
PS > New-CbcIoc -Feed $Feed -ReportId 59ac2095-c663-44cd-99cb-4ce83e7aa894 -Body $Body

.EXAMPLE
PS > $Report = Get-CbcReport -FeedId JuXVurDTFmszw93it0Gvw -ReportId 59ac2095-c663-44cd-99cb-4ce83e7aa894
PS > New-CbcIoc -Report $Report -Body $Body
#>

function New-CbcIoc {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcIoc[]])]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$FeedId,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$ReportId,

        [Parameter(ParameterSetName = "Report", Mandatory = $true)]
        [CbcReport[]]$Report,

        [Parameter(ParameterSetName = "Report", Mandatory = $true)]
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [hashtable]$Body,

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
                    $Report = Get-CbcReport -FeedId $FeedId -Id $ReportId -Server $_
                    if ($Report.IocsV2.Count -ge 10000) {
                        Write-Error "Cannot add more IOCs to this report."
                    }
                    else {
                        $RequestBody = @{}
                        $UpdatedReport = @{}
                        $UpdatedReport.title = $Report.Title
                        $UpdatedReport.description = $Report.Description
                        $UpdatedReport.severity = $Report.Severity
                        $UpdatedReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                        $UpdatedReport.id = $Report.Id
                        $IOC = @{}
                        $IOC = $Body.Clone()
                        if (!$IOC.ContainsKey("id")) {
                            $IOC.id = [string](New-Guid)
                        }

                        $UpdatedReport.iocs_v2 = @()
                        if ($Report.IocsV2) {
                            $UpdatedReport.iocs_v2 += $Report.IocsV2
                            $UpdatedReport.iocs_v2 += $IOC
                           
                        }
                        else {
                            $UpdatedReport.iocs_v2 += $IOC
                        }

                        $RequestBody = $UpdatedReport        
                        $RequestBody = $RequestBody | ConvertTo-Json -Depth 100
        
                        $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                            -Method PUT `
                            -Server $_ `
                            -Params @($FeedId, $ReportId) `
                            -Body $RequestBody
        
                        if ($Response.StatusCode -ne 200) {
                            Write-Error -Message $("Cannot update reports for $($_)")
                        }
                        else {
                            return Initialize-CbcIoc $IOC $FeedId $ReportId $CurrentServer
                        }
                    }
                }
            }
            "Report" {
                $Report | ForEach-Object {
                    $CurrentReport = $_
                    if ($CurrentReport.IocsV2.Count -ge 10000) {
                        Write-Error "Cannot add more IOCs to this report."
                    }
                    else {
                        $RequestBody = @{}
                        $UpdatedReport = @{}
                        $UpdatedReport.title = $CurrentReport.Title
                        $UpdatedReport.description = $CurrentReport.Description
                        $UpdatedReport.severity = $CurrentReport.Severity
                        $UpdatedReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                        $UpdatedReport.id = $CurrentReport.Id
                        $IOC = $Body.Clone()
                        if (!$IOC.ContainsKey("id")) {
                            $IOC.id = [string](New-Guid)
                        }

                        $UpdatedReport.iocs_v2 = @()
                        if ($CurrentReport.IocsV2) {
                            $UpdatedReport.iocs_v2 = $CurrentReport.IocsV2 + $IOC
                        }
                        else {
                            $UpdatedReport.iocs_v2 = @($IOC)
                        }

                        $RequestBody = $UpdatedReport        
                        $RequestBody = $RequestBody | ConvertTo-Json -Depth 100
        
                        $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                            -Method PUT `
                            -Server $CurrentReport.Server `
                            -Params @($CurrentReport.FeedId, $CurrentReport.Id) `
                            -Body $RequestBody
        
                        if ($Response.StatusCode -ne 200) {
                            Write-Error -Message $("Cannot update reports for $($CurrentReport.Server)")
                        }
                        else {
                            return Initialize-CbcIoc $IOC $CurrentReport.FeedId $CurrentReport.Id $CurrentReport.Server
                        }
                    }
                }
            }
        }
    }
}