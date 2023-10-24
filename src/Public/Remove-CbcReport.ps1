using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet removes report from all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet removes report from all valid connections.
.PARAMETER Id
Filter param: Specify the Id of the report to remove.
.PARAMETER Report
Filter param: Specify the CbcReport to remove.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.NOTES
Permissions needed: DELETE org.feeds
.EXAMPLE
PS > Delete-CbcReport -Id R4cMgFIhRaakgk749MRr6Q

Removes report with specific ids from all connections. 
If you have multiple connections and you want report from a specific connection
you can add the `-Server` param.

PS > Delete-CbcReport -Id R4cMgFIhRaakgk749MRr6Q -Server $SpecifiedServer
.EXAMPLE
PS > $report = Get-CbcReport -Id R4cMgFIhRaakgk749MRr6Q
PS > Delete-CbcReport -Report $report

Removes specific report by proving CbcReport
#>

function Remove-CbcReport {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
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
                        $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                            -Method DELETE `
                            -Server $CurrentServer `
                            -Params $_
            
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
                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                        -Method DELETE `
                        -Server $_.Server `
                        -Params $_.Id

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