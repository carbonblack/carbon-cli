using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet updates feed info from all valid connections.
.LINK  
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet updates feed info from all valid connections.

A feed contains reports which have been gathered by a single source. They resemble "potential watchlists."
A watchlist may be easily subscribed to a feed, so that any reports in the feed act as if they were in the watchlist itself,
triggering logs or alerts as appropriate.
.PARAMETER Id
Specify the Id of the feed to update.
.PARAMETER Watchlist
Specify the CbcFeed to update.
.PARAMETER Name
Specify the new name for the feed.
.PARAMETER Summary
Specify the new summary for the feed.
.PARAMETER Category
Specify the new category for the feed.
.PARAMETER Alertable
Specify the new value for alertable for the feed.
.PARAMETER ProviderUrl
Specify the new value for provider url for the feed.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.NOTES
Permissions needed: UPDATE org.feeds
.EXAMPLE
PS > Set-CbcFeed -Id R4cMgFIhRaakgk749MRr6Q -Name demo -summary summary -Category category -Alertable $true -ProviderUrl http://test.test/

Update feed details with specific ids from all connections. 
If you have multiple connections and you want watchlist from a specific connection
you can add the `-Server` param.

PS > Set-CbcFeed -Id R4cMgFIhRaakgk749MRr6Q -Name demo -summary summary -Category category -Alertable $true -ProviderUrl http://test.test/ -Server $SpecifiedServer
.EXAMPLE
PS > $feed = Get-CbcFeed -Id R4cMgFIhRaakgk749MRr6Q
PS > Set-CbcFeed -Feed $feed -Name demo

Updates specific feeds by proving CbcFeed.
#>

function Set-CbcFeed {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Feed", Mandatory = $true)]
        [CbcFeed[]]$Feed,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Feed")]
        [string]$Name,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Feed")]
        [string]$Summary,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Feed")]
        [string]$Category,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Feed")]
        [bool]$Alertable,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Feed")]
        [string]$ProviderUrl,

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
                        $FeedObj = Get-CbcFeed -Id $_ -Server $CurrentServer
                        return Update-CbcFeed $FeedObj $PSBoundParameters
                    }
                }
            }
            "Feed" {
                $Feed | ForEach-Object {
                    return Update-CbcFeed $_ $PSBoundParameters
                }
            }
        }
    }
}