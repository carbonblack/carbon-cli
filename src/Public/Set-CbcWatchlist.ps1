using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet updates watchlist from all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet updates watchlist from all valid connections.

A watchlist contains reports (either directly or through a feed)
that the Carbon Black Cloud is matching against events coming from the endpoints. A positive match will trigger a "hit",
which may be logged or result in an alert.
.PARAMETER Id
Specify the Id of the watchlist to update.
.PARAMETER Watchlist
Specify the CbcWatchlist to update.
.PARAMETER Name
Specify the new name for the watchlist.
.PARAMETER Description
Specify the new description for the watchlist.
.PARAMETER AlertsEnabled
Specify the new value for alerts_enabled for the watchlist.
.PARAMETER TagsEnabled
Specify the new value for tags_enabled for the watchlist.
.PARAMETER AlertClassificationEnabled
Specify the new value for alert_classification_enabled for the watchlist.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.NOTES
Permissions needed: UPDATE org.watchlists
.EXAMPLE
PS > Set-CbcWatchlist -Id R4cMgFIhRaakgk749MRr6Q -Name demo -AlertsEnabled $true

Update watchlist name and alerts_enabled with specific ids from all connections. 
If you have multiple connections and you want watchlist from a specific connection
you can add the `-Server` param.

PS > Set-CbcWatchlist -Id R4cMgFIhRaakgk749MRr6Q -Name demo -AlertsEnabled $true -Server $SpecifiedServer
.EXAMPLE
PS > $watchlist = Get-CbcWatchlist -Id R4cMgFIhRaakgk749MRr6Q
PS > Set-CbcWatchlist -Watchlist $watchlist -Name demo

Updates specific watchlists by proving CbcWatchlist.
#>

function Set-CbcWatchlist {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Watchlist", Mandatory = $true)]
        [CbcWatchlist[]]$Watchlist,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Watchlist")]
        [string]$Name,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Watchlist")]
        [string]$Description,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Watchlist")]
        [bool]$AlertsEnabled,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Watchlist")]
        [bool]$TagsEnabled,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Watchlist")]
        [bool]$AlertClassificationEnabled,

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
                        $WatchlistObj = Get-CbcWatchlist -Id $_ -Server $CurrentServer
                        return Update-CbcWatchlist $WatchlistObj $PSBoundParameters
                    }
                }
            }
            "Watchlist" {
                $Watchlist | ForEach-Object {
                    return Update-CbcWatchlist $_ $PSBoundParameters
                }
            }
        }
    }
}