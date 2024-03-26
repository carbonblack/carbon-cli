using module ..\..\CarbonCLI\CarbonCLI.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name CarbonCLI -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\CarbonCLI\CarbonCLI.psm1 -Force
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

            It "Should return all feeds" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $Feed = Get-CbcFeed

                $Feed.Count | Should -Be 2
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
                $Feed[1].Name | Should -Be "Other Feed"
                $Feed[1].Server | Should -Be $s1
            }

            It "Should not return feeds, but exception" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 500
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                {Get-Feed -ErrorAction Stop} | Should -Throw
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
            }

            It "Should return all feeds for specific server" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1)
                }

                $Feed = Get-CbcFeed -Server $s1

                $Feed.Count | Should -Be 2
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
                $Feed[1].Name | Should -Be "Other Feed"
                $Feed[1].Server | Should -Be $s1
            }

            It "Should return all feeds for with specific name and access" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1)
                }

                $Feed = Get-CbcFeed -Name "My Feed", "ala" -Access "private" -Server $s1

                $Feed.Count | Should -Be 1
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
            }

            It "Should return all feeds for with specific name" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1)
                }

                $Feed = Get-CbcFeed -Name "My Feed", "ala" -Server $s1

                $Feed.Count | Should -Be 1
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
            }

            It "Should return all feeds for with access" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1)
                }

                $Feed = Get-CbcFeed -Access "private" -Server $s1

                $Feed.Count | Should -Be 1
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
            }

            It "Should return all feeds" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                        }
                    }
                    else {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds_2.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                $Feed = Get-CbcFeed

                $Feed.Count | Should -Be 3
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
                $Feed[1].Name | Should -Be "Other Feed"
                $Feed[1].Server | Should -Be $s1
                $Feed[2].Name | Should -Be "My Feed2"
                $Feed[2].Server | Should -Be $s2
            }

            It "Should return all feeds with specified ids" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                        }
                    }
                    else {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds_2.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                $Feed = Get-CbcFeed -Id ABCDEFGHIJKLMNOPQRSTUVWX

                $Feed.Count | Should -Be 2
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
                $Feed[1].Name | Should -Be "My Feed2"
                $Feed[1].Server | Should -Be $s2
            }

            It "Should return all feeds with specified ids - exception" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                        }
                    }
                    else {
                        @{
                            StatusCode = 500
                            Content    = ""
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                $Feed = Get-CbcFeed -Id ABCDEFGHIJKLMNOPQRSTUVWX

                $Feed.Count | Should -Be 1
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
            }
        }
    }
}
