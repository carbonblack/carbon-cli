using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
    Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Get-CbcReport" {
    Context "When using the 'default' parameter set" {
        Context "When using one connection" {
            BeforeAll {
                $Uri1 = "https://t.te1/"
                $Org1 = "test1"
                $secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
                
			    $s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
                $global:DefaultCbcServers = [System.Collections.ArrayList]@()
                $global:DefaultCbcServers.Add($s1) | Out-Null
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
            }

            It "Should return all reports for a feed" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/reports.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $Report = Get-CbcReport -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX"

                $Report.Count | Should -Be 1
                $Report[0].Title | Should -Be "yara"
                $Report[0].Server | Should -Be $s1
            }

            It "Should not return reports, but exception" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 500
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                {Get-CbcReport -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX" -ErrorAction Stop} | Should -Throw
            }

            It "Should not return reports by CbcFeed, but exception" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 500
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                {Get-CbcReport -Feed $feed1 -ErrorAction Stop} | Should -Throw
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
                $feed2 = [CbcFeed]::new(
                    "ABCDEFGHIJKLMNOPQRSTUVWX",
                    "My Feed",
                    "ABCD1234",
                    "https://example.com",
                    "Example Feed",
                    "None",
                    $true,
                    "private",
                    $s2
                )
            }

            It "Should return all reports for specific server" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/reports.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $Report = Get-CbcReport -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX" -Server $s1

                $Report.Count | Should -Be 1
                $Report[0].Title | Should -Be "yara"
                $Report[0].Server | Should -Be $s1
            }

            It "Should return all reports" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/reports.json"
                        }
                    }
                    else {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/reports_2.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                $Report = Get-CbcReport -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX"

                $Report.Count | Should -Be 3
                $Report[0].Title | Should -Be "yara"
                $Report[0].Server | Should -Be $s1
                $Report[1].Title | Should -Be "yara2"
                $Report[1].Server | Should -Be $s2
                $Report[2].Title | Should -Be "yara3"
                $Report[2].Server | Should -Be $s2
            }

            It "Should return all reports with specific id" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/reports.json"
                        }
                    }
                    else {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/reports_2.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                $Report = Get-CbcReport -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX" -Id "1"

                $Report.Count | Should -Be 2
                $Report[0].Title | Should -Be "yara"
                $Report[0].Server | Should -Be $s1
                $Report[1].Title | Should -Be "yara2"
                $Report[1].Server | Should -Be $s2
            }

            It "Should return all reports with specific id for specific server" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/reports_2.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1)
                }

                $Report = Get-CbcReport -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX" -Id "1" -Server $s1

                $Report.Count | Should -Be 1
                $Report[0].Title | Should -Be "yara2"
                $Report[0].Server | Should -Be $s1
            }

            It "Should return all reports by CbcFeed" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/reports.json"
                        }
                    }
                    else {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/reports_2.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                $Report = Get-CbcReport -Feed $feed1, $feed2

                $Report.Count | Should -Be 3
                $Report[0].Title | Should -Be "yara"
                $Report[0].Server | Should -Be $s1
                $Report[1].Title | Should -Be "yara2"
                $Report[1].Server | Should -Be $s2
                $Report[2].Title | Should -Be "yara3"
                $Report[2].Server | Should -Be $s2
            }

            It "Should return all reports with specific id by CbcFeed" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/reports.json"
                        }
                    }
                    else {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/reports_2.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                $Report = Get-CbcReport -Feed $feed1, $feed2 -Id "1"

                $Report.Count | Should -Be 2
                $Report[0].Title | Should -Be "yara"
                $Report[0].Server | Should -Be $s1
                $Report[1].Title | Should -Be "yara2"
                $Report[1].Server | Should -Be $s2
            }
        }
    }
}
