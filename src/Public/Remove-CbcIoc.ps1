using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet removes ioc from all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/ioc-api
.SYNOPSIS
This cmdlet removes ioc from all valid connections.
.PARAMETER Id
Filter param: Specify the Id of the ioc to remove.
.PARAMETER Ioc
Filter param: Specify the CbcIoc to remove.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.NOTES
Permissions needed: DELETE org.feeds
.EXAMPLE
PS > Delete-CbcIoc -Id R4cMgFIhRaakgk749MRr6Q

Removes ioc with specific ids from all connections. 
If you have multiple connections and you want ioc from a specific connection
you can add the `-Server` param.

PS > Delete-CbcIoc -Id R4cMgFIhRaakgk749MRr6Q -Server $SpecifiedServer
.EXAMPLE
PS > $ioc = Get-CbcIoc -Id R4cMgFIhRaakgk749MRr6Q
PS > Delete-CbcIoc -Ioc $ioc

Removes specific ioc by proving CbcIoc
#>

function Remove-CbcIoc {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$ReportId,

        [Parameter(ParameterSetName = "Ioc", Mandatory = $true)]
        [CbcIoc[]]$Ioc,

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
                        $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["IOC"]["Details"] `
                            -Method DELETE `
                            -Server $CurrentServer `
                            -Params @($ReportId, $_)
            
                        if ($Response.StatusCode -ne 204) {
                            Write-Error -Message $("Cannot delete ioc(s) for $($CurrentServer)")
                        }
                        else {
                            Write-Debug -Message $("Ioc deleted $($_)")
                        }
                    }
                }
            }
            "Ioc" {
                $Ioc | ForEach-Object {
                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["IOC"]["Details"] `
                        -Method DELETE `
                        -Server $_.Server `
                        -Params ($_.ReportId, $_.Id)

                    if ($Response.StatusCode -ne 204) {
                        Write-Error -Message $("Cannot delete ioc(s) for $($_.Server)")
                    }
                    else {
                        Write-Debug -Message $("Ioc deleted $($_.Id)")
                    }
                }
            }
        }
    }
}