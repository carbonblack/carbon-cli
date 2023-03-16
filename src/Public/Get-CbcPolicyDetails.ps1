using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns detailed information about a policy specified by its Id.
.PARAMETER Id
Specifies the Id of the policy object for which details to be extracted 
.PARAMETER Server
Sets a specified CBC Server from the current connections to execute the cmdlet with.
The Id property is unique within the boundaries of a single CBC Server connection
.OUTPUTS
CbcPolicyDetails
.EXAMPLE
PS > Get-CbcPolicyDetails -Id 234567, 12345

Returns detailed information about a policies with corresponding ids: 234567 and 12345

If you have multiple connections and you want to retrieve policies from a specific server,
you can add the `-Server` param.

PS > Get-CbcPolicyDetails -Id 234567 -Server $SpecifiedServer
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/policy-service/
#>

# TODO: Add tests to cover Get-CbcPolicyDetails cmdlet
function Get-CbcPolicyDetails {
    [CmdletBinding()]
    [OutputType([CbcPolicyDetails])]
    param(
        [Parameter(
            ValueFromPipeline = $true,
			Mandatory = $true,
			Position = 0)]
		[long[]]$Id,
        [CbcServer[]]$Server
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
            Write-Debug "Retrieving policies from $_ server"
            $CurrentServer = $_
            $Id | ForEach-Object {
                Write-Debug "Retrieving policy details for policy with id: $_ "
                
                $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Policies"]["Details"] `
                -Method GET `
                -Server $CurrentServer `
                -Params $_
                
                $JsonContent = $Response.Content | ConvertFrom-Json
                
                return Initialize-CbcPolicyDetails $JsonContent $CurrentServer
            }
            
        }
    }

    end {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
    }
}
