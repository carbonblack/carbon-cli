using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet removes report from all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet removes report from all valid connections.

A report groups one or more IOCs together, which may reflect a number of possible conditions to look for, or a number
of conditions related to a particular target program or type of malware. Reports can be used to organize IOCs.
.PARAMETER FeedId
Filter param: Specify the Id of the feed to which the report to be removed belongs.
.PARAMETER Id
Filter param: Specify the Id of the report to remove.
.PARAMETER Report
Filter param: Specify the CbcReport to remove (either FeedId & Id or Report should be provided).
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.NOTES
Permissions needed: DELETE org.feeds
.EXAMPLE
PS > Remove-CbcReport -FeedId 5hBIvXltQqy0oAAqdEh0A -Id R4cMgFIhRaakgk749MRr6Q, R4cMgFIhRaakgk749MRr62

Removes report with specific ids from all connections. 
If you have multiple connections and you want report from a specific connection
you can add the `-Server` param.

PS > Remove-CbcReport -FeedId 5hBIvXltQqy0oAAqdEh0A -Id R4cMgFIhRaakgk749MRr6Q, R4cMgFIhRaakgk749MRr62 -Server $SpecifiedServer
.EXAMPLE
PS > $report = Get-CbcReport -FeedId 5hBIvXltQqy0oAAqdEh0A -Id R4cMgFIhRaakgk749MRr6Q
PS > Remove-CbcReport -Report $report

Removes specific report by proving CbcReport.
#>

function Remove-CbcReport {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$FeedId,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Report", Mandatory = $true)]
        [CbcReport[]]$Report,

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
                        # currently using Watchlist API, because Feed Manager API is not working
                        $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Watchlist"]["Report"] `
                            -Method DELETE `
                            -Server $CurrentServer `
                            -Params @($FeedId + "-" + $_)
            
                        if ($Response.StatusCode -ne 204) {
                            Write-Error -Message $("Cannot delete report(s) for $($CurrentServer)")
                        }
                        else {
                            Write-Debug -Message $("Report deleted $($_)")
                        }
                    }
                }
            }
            "Report" {
                $Report | ForEach-Object {
                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Watchlist"]["Report"] `
                        -Method DELETE `
                        -Server $_.Server `
                        -Params @($_.FeedId + "-" + $_.Id)

                    if ($Response.StatusCode -ne 204) {
                        Write-Error -Message $("Cannot delete report(s) for $($_.Server)")
                    }
                    else {
                        Write-Debug -Message $("Report deleted $($_.Id)")
                    }
                }
            }
        }
    }
}