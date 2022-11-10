<#
.DESCRIPTION
This cmdlet returns an overview of the policies available in the organization
.PARAMETER Server
Sets a specified server to execute the cmdlet with.
.OUTPUTS

.LINK
Online Version: http://devnetworketc/
#>
function Get-Policy{
    Param(
        [PSCustomObject] $Server
    )

    Process{
        $ExecuteTo = $CBC_CONFIG.currentConnections
        if ($Server) {
            $ExecuteTo = @($Server)
        }
        $ExecuteTo | ForEach-Object {
            $Response = Invoke-CBCRequest -Server $_ `
                -Endpoint $CBC_CONFIG.endpoints["Policy"]["Summary"] `
                -Method GET `
            
            return $Response.Content | ConvertFrom-Json -AsHashtable
        }
    }
}