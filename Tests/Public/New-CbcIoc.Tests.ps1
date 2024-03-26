using module ..\..\CarbonCLI\CarbonCLI.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name CarbonCLI -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\CarbonCLI\CarbonCLI.psm1 -Force
}

AfterAll {
    Remove-Module -Name CarbonCLI -Force
}

Describe "New-CbcIoc" {
    Context "When using the 'default' parameter set" {
        Context "When using one connection" {
            BeforeAll {
                $Uri1 = "https://t.te1/"
                $Org1 = "test1"
                $secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
                
			    $s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
                $global:DefaultCbcServers = [System.Collections.ArrayList]@()
                $global:DefaultCbcServers.Add($s1) | Out-Null
                $ioc = @{
                    "id" = "id123"
                    "match_type" = "equality"
                    "values" = @("SHA256HashOfAProcess")
                    "field" = "process_sha256"
                }
                $feed1 = [CbcFeed]::new(
                    "ABCDEFGHIJKLMNOPQRSTUVWX",
                    "My Feed",
                    "ABCD1234",
                    "https://example.com",
                    "Example Feed",
                    "None",
                    $true,
                    "private",
                    $s1
                )
                $report1 = [CbcReport]::new(
                    "xxx",
                    "yara",
                    "description",
                    5,
                    "google.com",
                    @(),
                    "visible",
                    "ABCDEFGHIJKLMNOPQRSTUVWX1",
                    $s1
                )
            }

            It "Should create ioc" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    $report1
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1
                }

                $Ioc = New-CbcIoc -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -ReportId ABCDEFGHIJKLMNOPQRSTUVWX1 -Body $ioc

                $Ioc.Count | Should -Be 1
                $Ioc[0].MatchType | Should -Be "equality"
                $Ioc[0].Server | Should -Be $s1
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
                $feed1 = [CbcFeed]::new(
                    "ABCDEFGHIJKLMNOPQRSTUVWX",
                    "My Feed",
                    "ABCD1234",
                    "https://example.com",
                    "Example Feed",
                    "None",
                    $true,
                    "private",
                    $s1
                )
                $report1 = [CbcReport]::new(
                    "xxx",
                    "yara",
                    "description",
                    5,
                    "google.com",
                    @(),
                    "visible",
                    "ABCDEFGHIJKLMNOPQRSTUVWX1",
                    $s1
                )
                $ioc = @{
                    "id" = "id123"
                    "match_type" = "equality"
                    "values" = @("SHA256HashOfAProcess")
                    "field" = "process_sha256"
                }
                $report2 = [CbcReport]::new(
                    "xxx2",
                    "yara",
                    "description",
                    5,
                    "google.com",
                    @($ioc),
                    "visible",
                    "ABCDEFGHIJKLMNOPQRSTUVWX1",
                    $s2
                )
            }

            It "Should create ioc for specific connections" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    $report1
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1
                }

                $Ioc = New-CbcIoc -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -ReportId ABCDEFGHIJKLMNOPQRSTUVWX1 -Body $ioc -Server $s1

                $Ioc.Count | Should -Be 1
                $Ioc[0].MatchType | Should -Be "equality"
                $Ioc[0].Server | Should -Be $s1
            }

            It "Should create ioc for specific connections - exception" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    $report1
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 400
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1
                }

                {New-CbcIoc -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -ReportId ABCDEFGHIJKLMNOPQRSTUVWX1 -Body $ioc -Server $s1 -ErrorAction Stop } | Should -Throw
            }

            It "Should create ioc for all connections" {
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
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Body | ConvertFrom-Json).iocs_v2.Count -ge 1
                }

                $Ioc = New-CbcIoc -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -ReportId ABCDEFGHIJKLMNOPQRSTUVWX1 -Body $ioc

                $Ioc.Count | Should -Be 2
                $Ioc[0].MatchType | Should -Be "equality"
                $Ioc[0].Server | Should -Be $s1
                $Ioc[1].MatchType | Should -Be "equality"
                $Ioc[1].Server | Should -Be $s2
            }

            It "Should create ioc for CbcReport" {
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
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Body | ConvertFrom-Json).iocs_v2.Count -ge 1
                }

                $Ioc = New-CbcIoc -Report $report1, $report2 -Body $ioc

                $Ioc.Count | Should -Be 2
                $Ioc[0].MatchType | Should -Be "equality"
                $Ioc[0].Server | Should -Be $s1
                $Ioc[1].MatchType | Should -Be "equality"
                $Ioc[1].Server | Should -Be $s2
            }

            It "Should not create ioc for CbcReport - exception" {
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
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Body | ConvertFrom-Json).iocs_v2.Count -ge 1
                }

                {New-CbcIoc -Report $report1, $report2 -Body $ioc -ErrorAction Stop} | Should -Throw
            }
        }
    }
}
