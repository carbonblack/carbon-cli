using module ..\..\src\CarbonCLI.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name CarbonCLI -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\src\CarbonCLI.psm1 -Force
}

AfterAll {
    Remove-Module -Name CarbonCLI -Force
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
                $ioc1 = @{
                    "id" = "id123"
                    "match_type" = "equality"
                    "values" = @("SHA256HashOfAProcess")
                    "field" = "process_sha256"
                }
                $ioc2 = @{
                    "id" = "id1234"
                    "match_type" = "equality"
                    "values" = @("SHA256HashOfAProcess")
                    "field" = "process_sha256"
                }
                $report1 = [CbcReport]::new(
                    "xxx",
                    "yara",
                    "description",
                    5,
                    "google.com",
                    @($ioc1, $ioc2),
                    "visible",
                    "ABCDEFGHIJKLMNOPQRSTUVWX1",
                    $s1
                )
            }

            It "Should remove ioc" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    $report1
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1
                }
                { Remove-CbcIoc -Id id1234 -FeedId ABCDEFGHIJKLMNOPQRSTUVWX1 -ReportId ABCDEFGHIJKLMNOPQRSTUVWX -ErrorAction Stop } | Should -Not -Throw
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
                $ioc1 = @{
                    "id" = "id123"
                    "match_type" = "equality"
                    "values" = @("SHA256HashOfAProcess")
                    "field" = "process_sha256"
                }
                $ioc2 = @{
                    "id" = "id1234"
                    "match_type" = "equality"
                    "values" = @("SHA256HashOfAProcess")
                    "field" = "process_sha256"
                }
                $report1 = [CbcReport]::new(
                    "xxx",
                    "yara",
                    "description",
                    5,
                    "google.com",
                    @($ioc1, $ioc2),
                    "visible",
                    "ABCDEFGHIJKLMNOPQRSTUVWX1",
                    $s1
                )
                $report2 = [CbcReport]::new(
                    "xxx",
                    "yara",
                    "description",
                    5,
                    "google.com",
                    @($ioc1),
                    "visible",
                    "ABCDEFGHIJKLMNOPQRSTUVWX1",
                    $s2
                )
                $iocObj = [CbcIoc]::new(
                    "id123",
                    "equality",
                    @("xxx"),
                    "process_hash",
                    "",
                    "ABCDEFGHIJKLMNOPQRSTUVWX1",
                    "ABCDEFGHIJKLMNOPQRSTUVWX",
                    $s1
                )
            }

            It "Should delete ioc for specific connections" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    $report1
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1
                }
                { Remove-CbcIoc -Id id1234 -FeedId ABCDEFGHIJKLMNOPQRSTUVWX1 -ReportId ABCDEFGHIJKLMNOPQRSTUVWX -Server $s1 -ErrorAction Stop } | Should -Not -Throw
            }

            It "Should delete ioc for all connections" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        $report1
                    }
                    else {
                        $report2
                    }
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1
                }
                { Remove-CbcIoc -Id id1234 -FeedId ABCDEFGHIJKLMNOPQRSTUVWX1 -ReportId ABCDEFGHIJKLMNOPQRSTUVWX -ErrorAction Stop } | Should -Not -Throw
            }

            It "Should try to delete ioc for all connections - exception" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        $report1
                    }
                    else {
                        $report2
                    }
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 500
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT"
                }
                { Remove-CbcIoc -Id id1234 -FeedId ABCDEFGHIJKLMNOPQRSTUVWX1 -ReportId ABCDEFGHIJKLMNOPQRSTUVWX -ErrorAction Stop } | Should -Throw
            }

            It "Should delete ioc - CbcIoc" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        $report1
                    }
                    else {
                        $report2
                    }
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT"
                }
                { Remove-CbcIoc -Ioc $iocObj -ErrorAction Stop } | Should -Not -Throw
            }

            It "Should delete ioc CbcIoc - exception" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        $report1
                    }
                    else {
                        $report2
                    }
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 500
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT"
                }
                { Remove-CbcIoc -Ioc $iocObj -ErrorAction Stop } | Should -Throw
            }
        }
    }
}
