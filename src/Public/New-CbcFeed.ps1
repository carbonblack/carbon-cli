using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet creates a feed in all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet creates a feed in all valid connections.
.PARAMETER Name
Name of the Feed (required)
.PARAMETER ProviderUrl
Provider URL of the Feed (required)
.PARAMETER Summary
Summary of the Feed (required)
.PARAMETER Category
Category of the Feed (required)
.PARAMETER Alertable
Optional indicator for noisy feeds to prevent alerting when a watchlist is subscribed.
.OUTPUTS
CbcFeed
.NOTES
Permissions needed: CREATE org.feeds
.EXAMPLE
PS > New-CbcFeed -Name myfeed -ProviderUrl http://test.test/ -Summary summary -Category category -Alertable $true

If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > New-CbcFeed -Name myfeed -ProviderUrl http://test.test/ -Summary summary -Category category -Alertable $true -Server $SpecifiedServer
.EXAMPLE
PS > New-CbcFeed -Body @{"name"= "myfeed"
>> "provider_url"  = "http://test.test/"
>> "summary" = "summary"
>> "category" = "category" 
>> "alertable" = $true}
#>

function New-CbcFeed {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcFeed])]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$Name,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$ProviderUrl,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$Summary,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$Category,

        [Parameter(ParameterSetName = "Default")]
        [bool]$Alertable,

        [Parameter(ParameterSetName = "CustomBody", Mandatory = $true)]
        [hashtable]$Body,

        [Parameter(ParameterSetName = "CustomBody")]
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
            if ($PSCmdlet.ParameterSetName -eq "Default") {
                $RequestBody = @{}
                $RequestBody.feedinfo = @{}
                $RequestBody.reports = @()
                $RequestBody.feedinfo.name = $Name
                $RequestBody.feedinfo.provider_url = $ProviderUrl
                $RequestBody.feedinfo.summary = $Summary
                $RequestBody.feedinfo.category = $Category
                if ($PSBoundParameters.ContainsKey("Alertable")) {
                    $RequestBody.feedinfo.alertable = $Alertable
                }
            }
            else {
                $RequestBody = $Body
            }
            $RequestBody = $RequestBody | ConvertTo-Json

            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Feed"]["Search"] `
                -Method POST `
                -Server $_ `
                -Body $RequestBody

            if ($Response.StatusCode -ne 200) {
                Write-Error -Message $("Cannot create feed for $($_)")
            }
            else {
                $JsonContent = $Response.Content | ConvertFrom-Json
                return Initialize-CbcFeedDetails $JsonContent.feedinfo $CurrentServer $JsonContent.reports
            }
        }
    }
}