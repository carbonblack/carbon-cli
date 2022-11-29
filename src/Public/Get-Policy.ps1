using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns an overview of the policies available in the organization.
.PARAMETER All
Returns a summary of all policies in the organisation.
.PARAMETER Id
Returns a detailed overview of a policy with the specified Id.
.PARAMETER CBCServer
Sets a specified CBC Server from the current connections to execute the cmdlet with.
.OUTPUTS
A Policy Object
.NOTES
-------------------------- Example 1 --------------------------
Get-Policy 
Returns a summary of all policies and the request is made with every current connection.

-------------------------- Example 2 --------------------------
Get-Policy -All
Returns a summary of all policies and the request is made with every current connection.

-------------------------- Example 3 --------------------------
Get-Policy -All -CBCServer $ServerObj
Returns a summary of all policies in the organisation but the request is made only with the connection with specified CBC server.

-------------------------- Example 4 --------------------------
Get-Policy "1234"
Returns a detailed overview of a policy with the specified Id.

-------------------------- Example 5 --------------------------
Get-Policy -Id "1234"
Returns a detailed overview of a policy with the specified Id.

-------------------------- Example 6 --------------------------
Get-Policy -Id "1234" -CBCServer $CBCServerObj
Returns a detailed overview of a policy with the specified Id but the request is made only with the connection with specified CBC server.

.LINK
Online Version: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/policy-service/
#>

function Get-Policy {
    [CmdletBinding(DefaultParameterSetName = "NoParams")]
    Param(
        [Parameter(ParameterSetName = "all", Position = 0)]
        [switch] $All,

        [Parameter(ParameterSetName = "id", Position = 0)]
        [array] $Id,

        [CBCServer] $CBCServer
    )

    Process {
        $ExecuteTo = $CBC_CONFIG.currentConnections
        if ($CBCServer) {
            $ExecuteTo = @($CBCServer)
        }
        switch ($PSCmdlet.ParameterSetName) {
            "NoParams" {
                $ExecuteTo | ForEach-Object {
                    $CurrentCBCServer = $_
                    $CBCServerName = "[{0}] {1}" -f $_.Org, $_.Uri
                    $Response = Invoke-CBCRequest -CBCServer $_ `
                        -Endpoint $CBC_CONFIG.endpoints["Policy"]["Summary"] `
                        -Method GET `
                    
                    if ($null -ne $Response) {
                        $ResponseContent = $Response.Content | ConvertFrom-Json
                        Write-Host "`r`n`tPolicy from: $CBCServerName`r`n"
                        $ResponseContent.policies | ForEach-Object {
                            $CurrentPolicy = $_
                            $PolicyObject = [PolicySummary]::new()
                            $PolicyObject.CBCServer = $CurrentCBCServer
                        ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                                $key = (ConvertTo-PascalCase $_)
                                $value = $CurrentPolicy.$_
                                $PolicyObject.$key = $value
                            }
                            $PolicyObject
                        }
                    }
                    else {
                        return [PolicySummary]::new()
                    }   
                }
            }
            "All" {
                $ExecuteTo | ForEach-Object {
                    $CurrentCBCServer = $_
                    $CBCServerName = "[{0}] {1}" -f $_.Org, $_.Uri
                    $Response = Invoke-CBCRequest -CBCServer $_ `
                        -Endpoint $CBC_CONFIG.endpoints["Policy"]["Summary"] `
                        -Method GET `
                    
                    if ($null -ne $Response) {
                        $ResponseContent = $Response.Content | ConvertFrom-Json
                        Write-Host "`r`n`tPolicy from: $CBCServerName`r`n"
                        $ResponseContent.policies | ForEach-Object {
                            $CurrentPolicy = $_
                            $PolicyObject = [PolicySummary]::new()
                            $PolicyObject.CBCServer = $CurrentCBCServer
                        ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                                $key = (ConvertTo-PascalCase $_)
                                $value = $CurrentPolicy.$_
                                $PolicyObject.$key = $value
                            }
                            $PolicyObject
                        }
                    }
                    else {
                        return [PolicySummary]::new()
                    } 
                }
            }
            "Id" {
                $ExecuteTo | ForEach-Object {
                    $CurrentCBCServer = $_
                    $CBCServerName = "[{0}] {1}" -f $_.Org, $_.Uri
                    $Response = Invoke-CBCRequest -CBCServer $_ `
                        -Endpoint $CBC_CONFIG.endpoints["Policy"]["Details"] `
                        -Method GET `
                        -Params @($Id)
                
                    if ($null -ne $Response) {
                        $ResponseContent = $Response.Content | ConvertFrom-Json

                        Write-Host "`r`n`tPolicy from: $CBCServerName`r`n"
                        $ResponseContent | ForEach-Object {
                            $CurrentPolicy = $_
                            $PolicyObject = [Policy]::new()
                            $PolicyObject.CBCServer = $CurrentCBCServer
                        ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                                $key = (ConvertTo-PascalCase $_)
                                $value = $CurrentPolicy.$_
                                if ($value -is [PSCustomObject]) {
                                    $PolicyObject.$key = (ConvertTo-HashTable $value)
                                }
                                elseif ($value -is [System.Object[]]) {
                                    $list = [System.Collections.ArrayList]@()
                                    foreach ($obj in $value) {
                                        if ($obj -is [PSCustomObject]) {
                                        ($list.Add((ConvertTo-HashTable $obj))) | Out-Null
                                        }
                                        else {
                                        ($list.Add($obj)) | Out-Null
                                        }
                                    }
                                    if ($list.Count -gt 0) {
                                        $PolicyObject.$key = $list
                                    }
                                }
                                else {
                                    $PolicyObject.$key = $value
                                }
                            }
                            $PolicyObject
                        }
                    }
                    else {
                        return [Policy]::new()
                    }
                    
                }
            }
        }
    }
}