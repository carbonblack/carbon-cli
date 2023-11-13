using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
    Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Get-CbcIoc" {
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

            It "Should return all ioc for a report" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/report.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $Ioc = Get-CbcIoc -Report $report1

                $Ioc.Count | Should -Be 1
                $Ioc[0].Id | Should -Be "IOC_ID_1"
                $Ioc[0].Server | Should -Be $s1
            }

            It "Should return all ioc for a feedid and reportid" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/report.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $Ioc = Get-CbcIoc -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX" -ReportId "ABCDEFGHIJKLMNOPQRSTUVWX1"

                $Ioc.Count | Should -Be 1
                $Ioc[0].Id | Should -Be "IOC_ID_1"
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
                    "id" = "IOC_ID_1"
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

            It "Should return all ioc for a report - exception" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 400
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }
                { Get-CbcIoc -Report $report1 -ErrorAction Stop } | Should -Throw
            }

            It "Should return all ioc for a report" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/report.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $Ioc = Get-CbcIoc -Report $report1

                $Ioc.Count | Should -Be 1
                $Ioc[0].Id | Should -Be "IOC_ID_1"
                $Ioc[0].Server | Should -Be $s1
            }

            It "Should return all ioc for a report and id" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/report.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $Ioc = Get-CbcIoc -Report $report1 -Id IOC_ID_1
                $Ioc.Count | Should -Be 1
                $Ioc[0].Server | Should -Be $s1
            }

            It "Should return all ioc for a report and id - none" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/report.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $Ioc = Get-CbcIoc -Report $report1 -Id fake
                $Ioc.Count | Should -Be 0
            }

            It "Should not return ioc for feedid and reportid - exception" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 400
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "GET"
                }

                { Get-CbcIoc -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX" -ReportId "ABCDEFGHIJKLMNOPQRSTUVWX1" -ErrorAction Stop } | Should -Throw
            }

            It "Should return all ioc for a feedid and reportid for all connections with id" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/report.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "GET"
                }

                $Ioc = Get-CbcIoc -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX" -ReportId "ABCDEFGHIJKLMNOPQRSTUVWX1" -Id IOC_ID_1

                $Ioc.Count | Should -Be 2
                $Ioc[0].Id | Should -Be "IOC_ID_1"
                $Ioc[0].Server | Should -Be $s1
                $Ioc[1].Id | Should -Be "IOC_ID_1"
                $Ioc[1].Server | Should -Be $s2
            }

            It "Should return all ioc for a feedid and reportid for all connections" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/report.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "GET"
                }

                $Ioc = Get-CbcIoc -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX" -ReportId "ABCDEFGHIJKLMNOPQRSTUVWX1"

                $Ioc.Count | Should -Be 2
                $Ioc[0].Id | Should -Be "IOC_ID_1"
                $Ioc[0].Server | Should -Be $s1
                $Ioc[1].Id | Should -Be "IOC_ID_1"
                $Ioc[1].Server | Should -Be $s2
            }

            It "Should return all ioc for a feedid and reportid for specific connection" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/report.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "GET"
                }

                $Ioc = Get-CbcIoc -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX" -ReportId "ABCDEFGHIJKLMNOPQRSTUVWX1" -Server $s1

                $Ioc.Count | Should -Be 1
                $Ioc[0].Id | Should -Be "IOC_ID_1"
                $Ioc[0].Server | Should -Be $s1
            }
        }
    }
}
