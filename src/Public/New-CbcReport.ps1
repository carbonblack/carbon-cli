using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet creates a report in all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet creates a report in all valid connections.
.PARAMETER FeedId
Id of the Feed to which this report will be added
.PARAMETER Feed
CbcFeed object
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
                        if (!$Body.ContainsKey("id")) {
                            $Body.id = [string](New-Guid)
                        }
                        $Body.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                        $RequestBody.reports += $Body
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
                    if (!$Body.ContainsKey("id")) {
                        $Body.id = [string](New-Guid)
                    }
                    $Body.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                    $RequestBody.reports += $Body
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