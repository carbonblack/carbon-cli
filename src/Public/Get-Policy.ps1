using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns an overview of the policies available in the organization.
.PARAMETER All
Returns a summary of all policies in the organisation.
.PARAMETER Id
Returns a detailed overview of a policy with the specified Id.
.PARAMETER Server
Sets a specified server to execute the cmdlet with.
.OUTPUTS
A Policy Object
.NOTES
-------------------------- Example 1 --------------------------
Get-Policy -All
Returns a summary of all policies in the organisation.

-------------------------- Example 2 --------------------------
Get-Policy -All -Server ServerObj
Returns a summary of all policies in the organisation but the request is made only with the connection with specified server.

-------------------------- Example 3 --------------------------
Get-Policy -Id "SomeId"
Returns a detailed overview of a policy with the specified Id.

-------------------------- Example 4 --------------------------
Get-Policy -Id "SomeId2" -Server ServerObj2
Returns a detailed overview of a policy with the specified Id but the request is made only with the connection with specified server.

.LINK
Online Version: http://devnetworketc/
#>

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
                    $ResponseContent | ForEach-Object {
                        $CurrentPolicy = $_
                        $PolicyObject = [Policy]::new()
                        ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                            $key = (ConvertTo-PascalCase $_)
                            $value = $CurrentPolicy.$_
                            if ($value -is [PSCustomObject]) {
                                $PolicyObject.$key = (ConvertTo-HashTable $value)
                            } elseif ($value -is [System.Object[]]) {
                                $list = [System.Collections.ArrayList]@()
                                foreach ($obj in $value) {
                                    if ($obj -is [PSCustomObject]) {
                                        ($list.Add((ConvertTo-HashTable $obj))) | Out-Null
                                    } else {
                                        ($list.Add($obj)) | Out-Null
                                    }
                                }
                                if ($list.Count -gt 0) {
                                    $PolicyObject.$key = $list
                                }
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