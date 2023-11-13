using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all feeds or specific feed from all valid connections.
.LINK  
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet returns all feeds or specific feed from all valid connections.

A feed contains reports which have been gathered by a single source. They resemble "potential watchlists."
A watchlist may be easily subscribed to a feed, so that any reports in the feed act as if they were in the watchlist itself,
triggering logs or alerts as appropriate.
.PARAMETER Id
Filter param: Specify the Id of the feeds to retrieve.
.PARAMETER Name
Filter param: Specify the Name of the feeds to retrieve.
.PARAMETER Access
Filter param: Specify the Access (private, public, reserved) of the feeds to retrieve.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.OUTPUTS
CbcFeed[]
.NOTES
Permissions needed: READ org.feeds
.EXAMPLE
PS > Get-CbcFeed

Returns all feeds from all connections. 
If you have multiple connections and you want feeds from a specific connection
you can add the `-Server` param.

PS > Get-CbcFeed -Server $SpecifiedServer
.EXAMPLE
PS > Get-CbcFeed -Id 5hBIvXltQqy0oAAqdEh0A, jwUoZu1WRBujSoCcYNa6fA

Returns the feeds with specified Ids.
.EXAMPLE
PS > Get-CbcFeed -Name "myfeed", "otherfeed" -Access "private", "public"

Returns the feeds with specified Name and Access.
#>

function Get-CbcFeed {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcFeed[]])]
    param(
        [Parameter(ParameterSetName = "Id")]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Default")]
        [string[]]$Name,

        [Parameter(ParameterSetName = "Default")]
        [string[]]$Access,

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
       
        $ExecuteServers | ForEach-Object {
            $CurrentServer = $_
  
            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Feed"]["Search"] `
                -Method GET `
                -Server $_ `

            if ($Response.StatusCode -ne 200) {
                Write-Error -Message $("Cannot get feed(s) for $($_)")
            }
            else {
                $JsonContent = $Response.Content | ConvertFrom-Json
                $JsonContent.results | ForEach-Object {
                    if ($PSBoundParameters.ContainsKey("Id")) {
                        if ($Id.Contains($_.id)) {
                            return Initialize-CbcFeed $_ $CurrentServer
                        }
                    }
                    elseif ($PSBoundParameters.ContainsKey("Name") -and $PSBoundParameters.ContainsKey("Access")) {
                        if ($Name.Contains($_.name) -and $Access.Contains($_.access)) {
                            return Initialize-CbcFeed $_ $CurrentServer
                        }
                    }
                    elseif ($PSBoundParameters.ContainsKey("Name")) {
                        if ($Name.Contains($_.name)) {
                            return Initialize-CbcFeed $_ $CurrentServer
                        }
                    }
                    elseif ($PSBoundParameters.ContainsKey("Access")) {
                        if ($Access.Contains($_.access)) {
                            return Initialize-CbcFeed $_ $CurrentServer
                        }
                    }
                    else {
                        return Initialize-CbcFeed $_ $CurrentServer
                    }
                }
            }
        }
    }
}