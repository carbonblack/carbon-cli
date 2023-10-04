using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
    Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "New-CbcReport" {
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
                $report1 = [CbcReport]::new(
                    "xxx",
                    "yara",
                    "description",
                    5,
                    "google.com",
                    @(),
                    "visible",
                    $s1
                )
            }

            It "Should create report" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Details"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                Mock Get-CbcReport -ModuleName PSCarbonBlackCloud {
                    $report1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).reports.Count -eq 2
                }

                $Report = New-CbcReport -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -Title yara2 -Description description -Severity 5

                $Report.Count | Should -Be 1
                $Report[0].Title | Should -Be "yara"
                $Report[0].Server | Should -Be $s1
            }

            It "Should create report using CbcFeed" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Details"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                Mock Get-CbcReport -ModuleName PSCarbonBlackCloud {
                    $report1
                } -ParameterFilter {
                    $Feed -eq $feed1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).reports.Count -eq 2
                }

                $Report = New-CbcReport -Feed $feed1 -Title yara2 -Description description -Severity 5

                $Report.Count | Should -Be 1
                $Report[0].Title | Should -Be "yara"
                $Report[0].Server | Should -Be $s1
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
                    $s1
                )
            }

            It "Should create feed for specific connections" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Details"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                Mock Get-CbcReport -ModuleName PSCarbonBlackCloud {
                    $report1
                } -ParameterFilter {
                    $FeedId -eq "ABCDEFGHIJKLMNOPQRSTUVWX"
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).reports.Count -eq 2
                }

                $Report = New-CbcReport -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -Title yara2 -Description description -Severity 5 -Server $s1

                $Report.Count | Should -Be 1
                $Report[0].Title | Should -Be "yara"
                $Report[0].Server | Should -Be $s1
            }

            It "Should create report for all connections" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Details"] -and
                    $Method -eq "GET"
                }

                Mock Get-CbcReport -ModuleName PSCarbonBlackCloud {
                    $report1
                } -ParameterFilter {
                    $FeedId -eq "ABCDEFGHIJKLMNOPQRSTUVWX"
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "POST" -and
                    ($Body | ConvertFrom-Json).reports.Count -eq 2
                }

                $Report = New-CbcReport -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -Title yara2 -Description description -Severity 5

                $Report.Count | Should -Be 2
                $Report[0].Title | Should -Be "yara"
                $Report[1].Title | Should -Be "yara"
            }

            It "Should create report for all connections - exception" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Details"] -and
                    $Method -eq "GET"
                }

                Mock Get-CbcReport -ModuleName PSCarbonBlackCloud {
                    $report1
                } -ParameterFilter {
                    $FeedId -eq "ABCDEFGHIJKLMNOPQRSTUVWX"
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = ""
                        }
                    }
                    else {
                        @{
                            StatusCode = 500
                            Content    = ""
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "POST" -and
                    ($Body | ConvertFrom-Json).reports.Count -eq 2
                }

                $Report = New-CbcReport -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -Title yara2 -Description description -Severity 5

                $Report.Count | Should -Be 1
                $Report[0].Title | Should -Be "yara"
                $Report[0].Server | Should -Be $s1
            }

            It "Should create report for all connections with custom body" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Details"] -and
                    $Method -eq "GET"
                }

                Mock Get-CbcReport -ModuleName PSCarbonBlackCloud {
                    $report1
                } -ParameterFilter {
                    $FeedId -eq "ABCDEFGHIJKLMNOPQRSTUVWX"
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "POST" -and
                    ($Body | ConvertFrom-Json).reports.Count -eq 2
                }

                $RequestBody = @{
                    "title" = "yara"
                    "description" = "test"
                    "severity" = 5
                }
                $Report = New-CbcReport -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -Body $RequestBody

                $Report.Count | Should -Be 2
                $Report[0].Title | Should -Be "yara"
                $Report[1].Title | Should -Be "yara"
            }

            It "Should create report for all connections with custom body from CbcFeed" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Details"] -and
                    $Method -eq "GET"
                }

                Mock Get-CbcReport -ModuleName PSCarbonBlackCloud {
                    $report1
                } -ParameterFilter {
                    $Feed -eq $feed1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "POST" -and
                    ($Body | ConvertFrom-Json).reports.Count -eq 2
                }

                $RequestBody = @{
                    "title" = "yara"
                    "description" = "test"
                    "severity" = 5
                }
                $Report = New-CbcReport -Feed $feed1 -Body $RequestBody

                $Report.Count | Should -Be 1
                $Report[0].Title | Should -Be "yara"
                $Report[0].Server | Should -Be $s1
            }

            It "Should create report for all connections with custom body from CbcFeed - exception" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Details"] -and
                    $Method -eq "GET"
                }

                Mock Get-CbcReport -ModuleName PSCarbonBlackCloud {
                    $report1
                } -ParameterFilter {
                    $Feed -eq $feed1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 500
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "POST" -and
                    ($Body | ConvertFrom-Json).reports.Count -eq 2
                }

                $RequestBody = @{
                    "title" = "yara"
                    "description" = "test"
                    "severity" = 5
                }
                $Report = New-CbcReport -Feed $feed1 -Body $RequestBody

                $Report.Count | Should -Be 0
            }
        }
    }
}
