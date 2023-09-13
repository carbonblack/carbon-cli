using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all feeds or specific feed from all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet returns all feeds or specific feed from all valid connections.
.PARAMETER Id
Filter param: Specify the Id of the feed to retrieve.
.OUTPUTS
CbcFeed[]
.NOTES
Permissions needed: READ org.feeds
.EXAMPLE
PS > Get-CbcFeed

Returns all feeds from all connections. 
If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > Get-CbcFeed -Server $SpecifiedServer
.EXAMPLE
PS > Get-CbcFeed -Id "11a1a1a1-b22b-3333-44cc-dd5555d5d55d"

Returns the feed with specified Id.
#>

function Get-CbcFeed {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcFeed[]])]
    param(
        [Parameter(ParameterSetName = "Id", Position = 0)]
        [string]$Id,

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
            $Endpoint = $null
            $Params = ""
            
            if ($PSCmdlet.ParameterSetName -eq "Id") {
                $Endpoint = $global:CBC_CONFIG.endpoints["Feed"]["Details"]
                $Params = $Id
            }
            else {
                $Endpoint = $global:CBC_CONFIG.endpoints["Feed"]["Search"]
            }
   
            $Response = Invoke-CbcRequest -Endpoint $Endpoint `
                -Method GET `
                -Server $_ `
                -Params $Params `

            if ($Response.StatusCode -ne 200) {
                Write-Error -Message $("Cannot get feed(s) for $($_)")
            }
            else {
                $JsonContent = $Response.Content | ConvertFrom-Json
                if ($PSCmdlet.ParameterSetName -eq "Id") {
                    return Initialize-CbcFeed $JsonContent.feedinfo $CurrentServer
                }
                else {
                    $JsonContent.results | ForEach-Object {
                        return Initialize-CbcFeed $_ $CurrentServer
                    }
                }
            }
        }
    }
}