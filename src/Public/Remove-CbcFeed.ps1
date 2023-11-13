using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet removes feed from all valid connections.
.LINK  
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet removes feed from all valid connections.

A feed contains reports which have been gathered by a single source. They resemble “potential watchlists.”
A watchlist may be easily subscribed to a feed, so that any reports in the feed act as if they were in the watchlist itself,
triggering logs or alerts as appropriate.
.PARAMETER Id
Filter param: Specify the Id of the feed to remove.
.PARAMETER Feed
Filter param: Specify the CbcFeed to remove.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.NOTES
Permissions needed: DELETE org.feeds
.EXAMPLE
PS > Remove-CbcFeed -Id R4cMgFIhRaakgk749MRr6Q

Removes feed with specific ids from all connections. 
If you have multiple connections and you want feed from a specific connection
you can add the `-Server` param.

PS > Remove-CbcFeed -Id R4cMgFIhRaakgk749MRr6Q -Server $SpecifiedServer
.EXAMPLE
PS > $feed = Get-CbcFeed -Id R4cMgFIhRaakgk749MRr6Q
PS > Remove-CbcFeed -Feed $feed

Removes specific feed by proving CbcFeed
#>

function Remove-CbcFeed {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Feed", Mandatory = $true)]
        [CbcFeed[]]$Feed,

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
                        $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Feed"]["Details"] `
                            -Method DELETE `
                            -Server $CurrentServer `
                            -Params $_
            
                        if ($Response.StatusCode -ne 204) {
                            Write-Error -Message $("Cannot delete feed(s) for $($CurrentServer)")
                        }
                        else {
                            Write-Debug -Message $("Feed deleted $($_)")
                        }
                    }
                }
            }
            "Feed" {
                $Feed | ForEach-Object {
                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Feed"]["Details"] `
                        -Method DELETE `
                        -Server $_.Server `
                        -Params $_.Id

                    if ($Response.StatusCode -ne 204) {
                        Write-Error -Message $("Cannot delete feed(s) for $($_.Server)")
                    }
                    else {
                        Write-Debug -Message $("Feed deleted $($_.Id)")
                    }
                }
            }
        }
    }
}