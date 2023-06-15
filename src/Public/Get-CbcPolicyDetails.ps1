using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns detailed information about a policy specified by its Id.
.PARAMETER Id
Specifies the Id of the policy object for which details to be extracted.
The Id property is unique within the boundaries of a single Cbc Server connection.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet against.
.OUTPUTS
CbcPolicyDetails
.EXAMPLE
PS > Get-CbcPolicyDetails -Id 234567, 12345

Returns detailed information about a policies with corresponding ids: 234567 and 12345

.EXAMPLE
PS > Get-CbcPolicyDetails -Id 234567 -Server $SpecifiedServer

If you have multiple connections and you want to retrieve policies from a specific connection,
you can add the `-Server` param
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/policy-service/
#>
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
            $ExecuteServers = $global:DefaultCbcServers
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

                if ($Response.StatusCode -ne 200) {
                    Write-Error -Message $("Cannot get policies for $($CurrentServer)")
                }
                else {
                    $JsonContent = $Response.Content | ConvertFrom-Json
                    return Initialize-CbcPolicyDetails $JsonContent $CurrentServer
                }
            }

        }
    }

    end {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
    }
}
