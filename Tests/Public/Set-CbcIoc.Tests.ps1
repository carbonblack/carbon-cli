using module ..\..\CarbonCLI\CarbonCLI.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name CarbonCLI -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\CarbonCLI\CarbonCLI.psm1 -Force
}

AfterAll {
    Remove-Module -Name CarbonCLI -Force
}

Describe "Set-CbcIoc" {
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
                $report1 = [CbcReport]::new(
                    "xxx",
                    "yara",
                    "description",
                    5,
                    "google.com",
                    @($ioc),
                    "visible",
                    "ABCDEFGHIJKLMNOPQRSTUVWX1",
                    $s1
                )
            }

            It "Should update ioc" {
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
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1 -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].match_type -eq "regex"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].field -eq "process_username"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].values -eq @("xx")
                }

                $Ioc = Set-CbcIoc -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -ReportId ABCDEFGHIJKLMNOPQRSTUVWX1 -Id "id123" -MatchType regex -Field process_username -Values @("xx")

                $Ioc.Count | Should -Be 1
                $Ioc[0].MatchType | Should -Be "regex"
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
                $ioc = @{
                    "id" = "id123"
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
                    @($ioc),
                    "visible",
                    "ABCDEFGHIJKLMNOPQRSTUVWX1",
                    $s1
                )
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
                $iocObj2 = [CbcIoc]::new(
                    "id124",
                    "equality",
                    @("xxx"),
                    "process_hash",
                    "",
                    "ABCDEFGHIJKLMNOPQRSTUVWX1",
                    "ABCDEFGHIJKLMNOPQRSTUVWX",
                    $s1
                )
            }

            It "Should update ioc for specific connections" {
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
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1 -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].match_type -eq "regex"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].field -eq "process_username"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].values -eq @("xx")
                }

                $Ioc = Set-CbcIoc -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -ReportId ABCDEFGHIJKLMNOPQRSTUVWX1 -Id "id123" -MatchType regex -Field process_username -Values @("xx") -Server $s1

                $Ioc.Count | Should -Be 1
                $Ioc[0].MatchType | Should -Be "regex"
                $Ioc[0].Server | Should -Be $s1
            }

            It "Should update ioc for specific connections - exception" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    $report1
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 500
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1 -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].match_type -eq "regex"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].field -eq "process_username"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].values -eq @("xx")
                }

                {Set-CbcIoc -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -ReportId ABCDEFGHIJKLMNOPQRSTUVWX1 -Id "id123" -MatchType regex -Field process_username -Values @("xx") -Server $s1 -ErrorAction Stop } | Should -Throw
            }

            It "Should update ioc for all connections - no updates" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        $report1
                    }
                    else {
                        $report2
                    }
                    
                }

                $Ioc = Set-CbcIoc -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -ReportId ABCDEFGHIJKLMNOPQRSTUVWX1 -Id "id123"
                $Ioc.Count | Should -Be 0
            }

            It "Should update ioc for all connections - no iocs to update" {
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
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1 -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].match_type -eq "equality"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].field -eq "process_sha256"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].values -eq @("SHA256HashOfAProcess")
                }

                $Ioc = Set-CbcIoc -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -ReportId ABCDEFGHIJKLMNOPQRSTUVWX1 -Id "id124" -MatchType regex -Field process_username -Values @("xx")
                $Ioc.Count | Should -Be 0
            }

            It "Should update ioc for all connections" {
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
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1 -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].match_type -eq "regex"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].field -eq "process_username"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].values -eq @("xx")
                }

                $Ioc = Set-CbcIoc -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -ReportId ABCDEFGHIJKLMNOPQRSTUVWX1 -Id "id123" -MatchType regex -Field process_username -Values @("xx")

                $Ioc.Count | Should -Be 2
                $Ioc[0].MatchType | Should -Be "regex"
                $Ioc[0].Server | Should -Be $s1
                $Ioc[1].MatchType | Should -Be "regex"
                $Ioc[1].Server | Should -Be $s2
            }

            It "Should update ioc by providing CbcIoc" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        $report1
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
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1 -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].match_type -eq "regex"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].field -eq "process_username"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].values -eq @("xx")
                }

                $Ioc = Set-CbcIoc -Ioc $iocObj -MatchType regex -Field process_username -Values @("xx")

                $Ioc.Count | Should -Be 1
                $Ioc[0].MatchType | Should -Be "regex"
                $Ioc[0].Server | Should -Be $s1
            }

            It "Should update ioc by providing CbcIoc - no iocs to update" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        $report1
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
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1 -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].match_type -eq "equality"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].field -eq "process_sha256"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].values -eq @("SHA256HashOfAProcess")
                }

                $Ioc = Set-CbcIoc -Ioc $iocObj2 -MatchType regex -Field process_username -Values @("xx")

                $Ioc.Count | Should -Be 0
            }

            It "Should update ioc by providing CbcIoc - no updates" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        $report1
                    }
                }

                $Ioc = Set-CbcIoc -Ioc $iocObj
                $Ioc.Count | Should -Be 0
            }

            It "Should not update ioc for CbcReport - exception" {
                Mock Get-CbcReport -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        $report1
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
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).iocs_v2.Count -eq 1 -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].match_type -eq "regex"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].field -eq "process_username"  -and
                    ($Body | ConvertFrom-Json).iocs_v2[0].values -eq @("xx")
                }

                $Ioc = Set-CbcIoc -Ioc $iocObj -MatchType regex -Field process_username -Values @("xx")
                {Set-CbcIoc -Ioc $iocObj -MatchType regex -Field process_username -Values @("xx") -ErrorAction Stop} | Should -Throw
            }
        }
    }
}
