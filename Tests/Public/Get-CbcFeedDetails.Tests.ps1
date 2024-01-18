using module ..\..\src\CarbonCLI.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name CarbonCLI -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\src\CarbonCLI.psm1 -Force
}

AfterAll {
    Remove-Module -Name CarbonCLI -Force
}

Describe "Get-CbcFeed" {
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

            It "Should return specific feed with feed id" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Details"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $Feed = Get-CbcFeedDetails -Id "ABCDEFGHIJKLMNOPQRSTUVWX"

                $Feed.Count | Should -Be 1
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
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
                    "My Feed2",
                    "ABCD1234",
                    "https://example.com",
                    "Example Feed",
                    "None",
                    $true,
                    "private",
                    $s2
                )
            }

            It "Should return feed by id for specific server" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Details"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1)
                }

                $Feed = Get-CbcFeedDetails -Id "ABCDEFGHIJKLMNOPQRSTUVWX" -Server $s1

                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
            }

            It "Should return feed by id - exception" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                        }
                    }
                    else {
                        @{
                            StatusCode = 500
                            Content    = ""
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Details"] -and
                    $Method -eq "GET"
                }

                $Feed = Get-CbcFeedDetails -Id "ABCDEFGHIJKLMNOPQRSTUVWX"

                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
            }

            It "Should return specific feed for CbcFeed" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Details"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1)
                }

                $Feed = Get-CbcFeedDetails -Feed $feed1
                $Feed.Count | Should -Be 1
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
                $Feed[0].Reports.Count | Should -Be 1
            }

            It "Should return specific feed for CbcFeed - exception" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                        }
                    }
                    else {
                        @{
                            StatusCode = 500
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/specific_feed.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Details"] -and
                    $Method -eq "GET"
                }

                $Feed = Get-CbcFeedDetails -Feed $feed1, $feed2

                $Feed.Count | Should -Be 1
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
                $Feed[0].Reports.Count | Should -Be 1
            }
        }
    }
}
