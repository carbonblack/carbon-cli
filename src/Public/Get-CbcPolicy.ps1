using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns an overview of the policies available in the organization.
.PARAMETER Id
Returns a detailed overview of a policy with the specified Id.
.PARAMETER Server
Sets a specified CBC Server from the current connections to execute the cmdlet with.
.OUTPUTS
CbcDevice[]
.EXAMPLE
PS > Get-CbcPolicy

Returns all policies from every connection.

If you have multiple connections and you want devices from a specific server
you can add the `-Server` param.

PS > Get-CbcPolicy -Server $SpecifiedServer
.EXAMPLE
PS > Get-CbcPolicy -Id "1"

Returns a policy that match this Id.

If you have multiple connections and you want devices from a specific server
you can add the `-Server` param.

PS > Get-CbcPolicy -Id "1" -Server $SpecifiedServer
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
        if ($Servers) {
            $ExecuteServers = $Servers
        }
        else {
            $ExecuteServers = $global:CBC_CONFIG.currentConnections
        }
        $ExecuteServers | ForEach-Object {
            $CurrentServer = $_

            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Policies"]["Search"] `
                -Method GET `
                -Server $_
            $JsonContent = $Response.Content | ConvertFrom-Json
            $JsonContent.policies | ForEach-Object {
                return Initialize-CbcPolicy $_ $CurrentServer
            }
        }
    }

    end {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
    }
}