using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet retrieves detailed information about specific feed specified by its id or the feed object itself.
.LINK  
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet retrieves detailed information about specific feed specified by its id or the feed object itself.

A feed contains reports which have been gathered by a single source. They resemble "potential watchlists."
A watchlist may be easily subscribed to a feed, so that any reports in the feed act as if they were in the watchlist itself,
triggering logs or alerts as appropriate.
.PARAMETER Id
Filter param: Specify the Ids of the feed details to retrieve.
.PARAMETER Feed
Filter param: Specify the CbcFeed of the feed details to retrieve.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.OUTPUTS
CbcFeedDetails[]
.NOTES
Permissions needed: READ org.feeds
.EXAMPLE
PS > Get-CbcFeedDetails -Id 5hBIvXltQqy0oAAqdEh0A, jwUoZu1WRBujSoCcYNa6fA

Returns the feed details with specified Id.

.EXAMPLE
PS > $Feed = Get-CbcFeed -Id 5hBIvXltQqy0oAAqdEh0A
PS > Get-CbcFeedDetails -Feed $Feed

Returns the feed details for a CbcFeed.
#>

function Get-CbcFeedDetails {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcFeedDetails[]])]
    param(
        [Parameter(ParameterSetName = "Id", Position = 0, Mandatory = $true)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Feed", Position = 0, Mandatory = $true)]
        [CbcFeed[]]$Feed,

        [Parameter(ParameterSetName = "Id")]
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
        if ($PSCmdlet.ParameterSetName -eq "Id") {
            $ExecuteServers | ForEach-Object {
                $CurrentServer = $_
      
                $Id | ForEach-Object {
                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Feed"]["Details"] `
                        -Method GET `
                        -Server  $CurrentServer `
                        -Params $_ `
    
                    if ($Response.StatusCode -ne 200) {
                        Write-Error -Message $("Cannot get feed(s) for $($CurrentServer)")
                    }
                    else {
                        $JsonContent = $Response.Content | ConvertFrom-Json
                        return Initialize-CbcFeedDetails $JsonContent.feedinfo $CurrentServer $JsonContent.reports
                    }
                }
            }
        }
        else {
            $Feed | ForEach-Object {
                $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Feed"]["Details"] `
                    -Method GET `
                    -Server  $_.Server`
                    -Params $_.Id `

                if ($Response.StatusCode -ne 200) {
                    Write-Error -Message $("Cannot get feed(s) for $($_.Server)")
                }
                else {
                    $JsonContent = $Response.Content | ConvertFrom-Json
                    return Initialize-CbcFeedDetails $JsonContent.feedinfo $_.Server $JsonContent.reports
                }
            }
        }
    }
}