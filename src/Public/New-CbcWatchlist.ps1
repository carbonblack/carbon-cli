using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet subscribes to feed in all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet subscribes to feed in all valid connections.
.PARAMETER Feed
CbcFeed (required)
.OUTPUTS
CbcWatchlist
.NOTES
Permissions needed: CREATE org.watchlists
.EXAMPLE
PS > New-CbcWatchlist -Feed (Get-CbcFeed -Id "xxxx")

If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > New-CbcWatchlist -Feed (Get-CbcFeed -Id "JuXVurDTFmszw93it0Gvw") -Server $SpecifiedServer
.EXAMPLE
#>

function New-CbcWatchlist {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcFeed])]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [CbcFeed]$Feed,

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
            $RequestBody = @{}
            $RequestBody.name = $Feed.Name
            $RequestBody.description = $Feed.Summary
            $RequestBody.alerts_enabled = $Feed.Alertable
            $RequestBody.classifier = @{
                "key" = "feed_id"
                "value" = $Feed.Id
            }
            
            $RequestBody = $RequestBody | ConvertTo-Json

            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Feed"]["Subscribe"] `
                -Method POST `
                -Server $_ `
                -Body $RequestBody

            if ($Response.StatusCode -ne 200) {
                Write-Error -Message $("Cannot subscribe to feed for $($_)")
            }
            else {
                $JsonContent = $Response.Content | ConvertFrom-Json
                return Initialize-CbcWatchlist $JsonContent $CurrentServer
            }
        }
    }
}