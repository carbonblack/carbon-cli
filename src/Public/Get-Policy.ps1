<#
.DESCRIPTION
This cmdlet returns an overview of the policies available in the organization
.PARAMETER Server
Sets a specified server to execute the cmdlet with.
.OUTPUTS

.LINK
Online Version: http://devnetworketc/
#>
using module ../PSCarbonBlackCloud.Classes.psm1
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
            $ServerName = "[{0}] {1}" -f $_.Org, $_.Uri
            $Response = Invoke-CBCRequest -Server $_ `
                -Endpoint $CBC_CONFIG.endpoints["Policy"]["Summary"] `
                -Method GET `
            
            $ResponseContent = $Response.Content | ConvertFrom-Json
            Write-Host "`r`n`tPolicy from: $ServerName`r`n"
            $ResponseContent.policies | ForEach-Object {
                $CurrentPolicy = $_
                $PolicyObject = [Policy]::new()
                ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                    $key = (ConvertTo-PascalCase $_)
                    $value = $CurrentPolicy.$_
                    $PolicyObject.$key = $value
                }
                $PolicyObject
            }
        }
    }
}