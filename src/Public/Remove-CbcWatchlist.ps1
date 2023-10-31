using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet removes watchlist from all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet removes watchlist from all valid connections.

A watchlist contains reports (either directly or through a feed)
that the Carbon Black Cloud is matching against events coming from the endpoints. A positive match will trigger a "hit",
which may be logged or result in an alert.
.PARAMETER Id
Filter param: Specify the Id of the watchlist to remove.
.PARAMETER Watchlist
Filter param: Specify the CbcWatchlist to remove.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.NOTES
Permissions needed: DELETE org.watchlists
.EXAMPLE
PS > Remove-CbcWatchlist -Id R4cMgFIhRaakgk749MRr6Q

Removes watchlist with specific ids from all connections. 
If you have multiple connections and you want watchlist from a specific connection
you can add the `-Server` param.

PS > Remove-CbcWatchlist -Id R4cMgFIhRaakgk749MRr6Q -Server $SpecifiedServer
.EXAMPLE
PS > $watchlist = Get-CbcWatchlist -Id R4cMgFIhRaakgk749MRr6Q
PS > Remove-CbcWatchlist -Watchlist $watchlist

Removes specific watchlist by proving CbcWatchlist
#>

function Remove-CbcWatchlist {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Watchlist", Mandatory = $true)]
        [CbcWatchlist[]]$Watchlist,

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
                        $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Watchlist"]["Details"] `
                            -Method DELETE `
                            -Server $CurrentServer `
                            -Params $_
            
                        if ($Response.StatusCode -ne 204) {
                            Write-Error -Message $("Cannot delete watchlist(s) for $($CurrentServer)")
                        }
                        else {
                            Write-Debug -Message $("Watchlist deleted $($_)")
                        }
                    }
                }
            }
            "Watchlist" {
                $Watchlist | ForEach-Object {
                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Watchlist"]["Details"] `
                        -Method DELETE `
                        -Server $_.Server `
                        -Params $_.Id

                    if ($Response.StatusCode -ne 204) {
                        Write-Error -Message $("Cannot delete watchlist(s) for $($_.Server)")
                    }
                    else {
                        Write-Debug -Message $("Watchlist deleted $($_.Id)")
                    }
                }
            }
        }
    }
}