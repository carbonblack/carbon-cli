using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns an overview of the available policies.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet against.
.OUTPUTS
CbcPolicy[]
.EXAMPLE
PS > Get-CbcPolicy

Returns all policies from every connection.

If you have multiple connections and you want policies from a specific connection
you can add the `-Server` param.

PS > Get-CbcPolicy -Server $SpecifiedServer

.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/policy-service/
#>

function Get-CbcPolicy {
    [CmdletBinding()]
    [OutputType([CbcPolicy[]])]
    param(
        [CBCServer]$Server
    )

    begin {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] function started"
    }

    process {
        if ($Server) {
            $ExecuteServers = $Server
        }
        else {
            $ExecuteServers = $global:CBC_CONFIG.currentConnections
        }
        $ExecuteServers | ForEach-Object {
            $CurrentServer = $_

            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Policies"]["Search"] `
                -Method GET `
                -Server $_

            if ($Response.StatusCode -ne 200) {
                Write-Error -Message $("Cannot get policies for $($_)")
            }
            else {
                $JsonContent = $Response.Content | ConvertFrom-Json
                $JsonContent.policies | ForEach-Object {
                    return Initialize-CbcPolicy $_ $CurrentServer
                }
            }
        }
    }

    end {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
    }
}