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
function Get-Policy {
    Param(
        [Parameter(ParameterSetName = "all")]
        [switch] $All,

        [Parameter(ParameterSetName = "id")]
        [string] $Id,

        [PSCustomObject] $Server
    )

    Process {
        $ExecuteTo = $CBC_CONFIG.currentConnections
        if ($Server) {
            $ExecuteTo = @($Server)
        }
        switch ($PSCmdlet.ParameterSetName) {
            "All" {
                $ExecuteTo | ForEach-Object {
                    $ServerName = "[{0}] {1}" -f $_.Org, $_.Uri
                    $Response = Invoke-CBCRequest -Server $_ `
                        -Endpoint $CBC_CONFIG.endpoints["Policy"]["Summary"] `
                        -Method GET `
                    
                    $ResponseContent = $Response.Content | ConvertFrom-Json
                    Write-Host "`r`n`tPolicy from: $ServerName`r`n"
                    $ResponseContent.policies | ForEach-Object {
                        $CurrentPolicy = $_
                        $PolicyObject = [PolicySummary]::new()
                        ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                            $key = (ConvertTo-PascalCase $_)
                            $value = $CurrentPolicy.$_
                            $PolicyObject.$key = $value
                        }
                        $PolicyObject
                    }
                }
            }
            "Id" {
                $ExecuteTo | ForEach-Object {
                    $ServerName = "[{0}] {1}" -f $_.Org, $_.Uri
                    $Response = Invoke-CBCRequest -Server $_ `
                        -Endpoint $CBC_CONFIG.endpoints["Policy"]["Details"] `
                        -Method GET `
                        -Params @($Id)
                
                    $ResponseContent = $Response.Content | ConvertFrom-Json

                    Write-Host "`r`n`tPolicy from: $ServerName`r`n"
                    Write-Host $ResponseContent
                    $ResponseContent | ForEach-Object {
                        $CurrentPolicy = $_
                        $PolicyObject = [Policy]::new()
                        ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                            $key = (ConvertTo-PascalCase $_)
                            $value = $CurrentPolicy.$_
                            if ($value -is [PSCustomObject]) {
                                $obj_hash = @{}
                                foreach ( $outer_name in $value.psobject.properties.name )
                                {
                                    $outer_key = (ConvertTo-PascalCase $outer_name)
                                    $obj_hash[$outer_key] = @{}
                                    foreach ( $nested in $value.$outer_name.psobject.properties.name ) {
                                        $inner_key = (ConvertTo-PascalCase $nested)
                                        $obj_hash[$outer_key][$inner_key] = $value.$outer_name.$nested
                                    }
                                }
                                $PolicyObject.$key = $obj_hash
                            } else {
                                $PolicyObject.$key = $value
                            }
                        }
                        $PolicyObject
                    }
                }
            }
        
        }
    }
}