using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
    Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Remove-CbcIoc" {
    Context "When using the 'default' parameter set" {
        Context "When using one connection" {
            BeforeAll {
                $Uri1 = "https://t.te1/"
                $Org1 = "test1"
                $secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
                
			    $s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
                $global:DefaultCbcServers = [System.Collections.ArrayList]@()
                $global:DefaultCbcServers.Add($s1) | Out-Null
            }

            It "Should remove ioc" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 204
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["IOC"]["Details"] -and
                    $Method -eq "DELETE" -and
                    ($Server -eq $s1)
                }
                { Remove-CbcIoc -Id iocid -ReportId ABCDEFGHIJKLMNOPQRSTUVWX -ErrorAction Stop } | Should -Not -Throw
            }
        }

        Context "When using multiple connections" {
            BeforeAll {
                $Uri1 = "https://t.te1/"
                $Org1 = "test1"
                $secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
                $Uri2 = "https://t.te2/"
                $Org2 = "test2"
                $secureToken2 = "test2" | ConvertTo-SecureString -AsPlainText
                $s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
                $s2 = [CbcServer]::new($Uri2, $Org2, $secureToken2)
                $global:DefaultCbcServers = [System.Collections.ArrayList]@()
                $global:DefaultCbcServers.Add($s1) | Out-Null
                $global:DefaultCbcServers.Add($s2) | Out-Null
                $ioc = [CbcIoc]::new(
                    "iocid",
                    "equality",
                    @("xxx"),
                    "process_hash",
                    "",
                    "ABCDEFGHIJKLMNOPQRSTUVWX",
                    $s1
                )
            }

            It "Should delete ioc for specific connections" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 204
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["IOC"]["Details"] -and
                    $Method -eq "DELETE" -and
                    ($Server -eq $s1)
                }
                { Remove-CbcIoc -Id iocid -ReportId ABCDEFGHIJKLMNOPQRSTUVWX -Server $s1 -ErrorAction Stop } | Should -Not -Throw
            }

            It "Should delete ioc for all connections" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 204
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["IOC"]["Details"] -and
                    $Method -eq "DELETE"
                }
                { Remove-CbcIoc -Id iocid -ReportId ABCDEFGHIJKLMNOPQRSTUVWX -ErrorAction Stop } | Should -Not -Throw
            }

            It "Should try to delete ioc for all connections - exception" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 500
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["IOC"]["Details"] -and
                    $Method -eq "DELETE"
                }
                { Remove-CbcIoc -Id iocid -ReportId ABCDEFGHIJKLMNOPQRSTUVWX -ErrorAction Stop } | Should -Throw
            }

            It "Should delete ioc - CbcIoc" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 204
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["IOC"]["Details"] -and
                    $Method -eq "DELETE" -and
                    ($Server -eq $s1)
                }
                { Remove-CbcIoc -Ioc $ioc -ErrorAction Stop } | Should -Not -Throw
            }

            It "Should delete ioc CbcIoc - exception" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 500
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["IOC"]["Details"] -and
                    $Method -eq "DELETE" -and
                    ($Server -eq $s1)
                }
                { Remove-CbcIoc -Ioc $ioc -ErrorAction Stop } | Should -Throw
            }
        }
    }
}
