using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns watchlist from all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet returns watchlist from all valid connections.

A watchlist contains reports (either directly or through a feed)
that the Carbon Black Cloud is matching against events coming from the endpoints. A positive match will trigger a "hit",
which may be logged or result in an alert.
.PARAMETER Id
Filter param: Specify the Id(s) of the watchlist to retrieve.
.PARAMETER Name
Filter param: Specify the Name(s) of the watchlist to retrieve.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.OUTPUTS
CbcWatchlist[]
.NOTES
Permissions needed: READ org.watchlists
.EXAMPLE
PS > Get-CbcWatchlist

Returns all watchlist from all connections. 
If you have multiple connections and you want watchlist from a specific connection
you can add the `-Server` param.

PS > Get-CbcWatchlist -Server $SpecifiedServer
.EXAMPLE
PS > Get-CbcWatchlist -Id 5hBIvXltQqy0oAAqdEh0A, jwUoZu1WRBujSoCcYNa6fA

Returns the watchlist with specified Ids.
.EXAMPLE
PS > Get-CbcWatchlist -Name demo, demo2

Returns the watchlist with specified names.
#>

function Get-CbcWatchlist {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcWatchlist[]])]
    param(
        [Parameter(ParameterSetName = "Default")]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Name")]
        [string[]]$Name,

        [Parameter(ParameterSetName = "Name")]
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

            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Watchlist"]["Search"] `
                -Method GET `
                -Server $_

            if ($Response.StatusCode -ne 200) {
                Write-Error -Message $("Cannot get watchlist(s) for $($_)")
            }
            else {
                $JsonContent = $Response.Content | ConvertFrom-Json
                $JsonContent.results | ForEach-Object {
                    if ($PSBoundParameters.ContainsKey("Id")) {
                        if ($Id.Contains($_.id)) {
                            return Initialize-CbcWatchlist $_ $CurrentServer
                        }
                    }
                    elseif ($PSBoundParameters.ContainsKey("Name")) {
                        if ($Name.Contains($_.name)) {
                            return Initialize-CbcWatchlist $_ $CurrentServer
                        }
                    }
                    else {
                        return Initialize-CbcWatchlist $_ $CurrentServer
                    }
                }
            }
        }
    }
}