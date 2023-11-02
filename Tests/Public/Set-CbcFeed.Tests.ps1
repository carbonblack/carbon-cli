using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
    Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Set-CbcFeed" {
    Context "When using the 'default' parameter set" {
        Context "When using one connection" {
            BeforeAll {
                $Uri1 = "https://t.te1/"
                $Org1 = "test1"
                $secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
                
			    $s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
                $global:DefaultCbcServers = [System.Collections.ArrayList]@()
                $global:DefaultCbcServers.Add($s1) | Out-Null
                $feed = [CbcFeed]::new(
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

            It "Should update feed" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/create_feed.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["FeedInfo"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).provider_url -eq "test2.com" -and
                    ($Body | ConvertFrom-Json).summary -eq "test" -and
                    ($Body | ConvertFrom-Json).category -eq "test" -and
                    ($Body | ConvertFrom-Json).alertable -eq $false
                }
                $feed = Set-CbcFeed -Id ABCDEFGHIJKLMNOPQRSTUVWX -Name "My Feed" -ProviderUrl "test2.com" -Summary test -Category test -Alertable $false
                $feed.Count | Should -Be 1
			    $feed[0].Server | Should -Be $s1
			    $feed[0].Name | Should -Be "My Feed"
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
                $feed = [CbcFeed]::new(
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

            It "Should update feed for specific connections" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/create_feed.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["FeedInfo"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).provider_url -eq "test2.com" -and
                    ($Body | ConvertFrom-Json).summary -eq "test" -and
                    ($Body | ConvertFrom-Json).category -eq "test" -and
                    ($Body | ConvertFrom-Json).alertable -eq $false
                }
                $feed = Set-CbcFeed -Id ABCDEFGHIJKLMNOPQRSTUVWX -Name "My Feed" -ProviderUrl "test2.com" -Summary test -Category test -Alertable $false -Server $s1
                $feed.Count | Should -Be 1
			    $feed[0].Server | Should -Be $s1
			    $feed[0].Name | Should -Be "My Feed"
            }

            It "Should update feed for all connections" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET"
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/create_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["FeedInfo"] -and
                    $Method -eq "PUT" -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).provider_url -eq "test2.com" -and
                    ($Body | ConvertFrom-Json).summary -eq "test" -and
                    ($Body | ConvertFrom-Json).category -eq "test" -and
                    ($Body | ConvertFrom-Json).alertable -eq $false
                }

                $feed = Set-CbcFeed -Id ABCDEFGHIJKLMNOPQRSTUVWX -Name "My Feed" -ProviderUrl "test2.com" -Summary test -Category test -Alertable $false
                $feed.Count | Should -Be 2
			    $feed[0].Server | Should -Be $s1
			    $feed[0].Name | Should -Be "My Feed"
                $feed[1].Server | Should -Be $s2
			    $feed[1].Name | Should -Be "My Feed"
            }

            It "Should try to update feed for all connections - exception" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET"
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 500
                        Content = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["FeedInfo"] -and
                    $Method -eq "PUT" -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).provider_url -eq "test2.com" -and
                    ($Body | ConvertFrom-Json).summary -eq "test" -and
                    ($Body | ConvertFrom-Json).category -eq "test" -and
                    ($Body | ConvertFrom-Json).alertable -eq $false
                }
                { Set-CbcFeed -Id ABCDEFGHIJKLMNOPQRSTUVWX -Name "My Feed" -ProviderUrl "test2.com" -Summary test -Category test -Alertable $false -ErrorAction Stop } | Should -Throw
            }

            It "Should update feed - CbcFeed" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/create_feed.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["FeedInfo"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).provider_url -eq "test2.com" -and
                    ($Body | ConvertFrom-Json).summary -eq "test" -and
                    ($Body | ConvertFrom-Json).category -eq "test" -and
                    ($Body | ConvertFrom-Json).alertable -eq $false
                }
                $feed = Set-CbcFeed -Feed $feed -Name "My Feed" -ProviderUrl "test2.com" -Summary test -Category test -Alertable $false
                $feed.Count | Should -Be 1
			    $feed[0].Server | Should -Be $s1
			    $feed[0].Name | Should -Be "My Feed"
            }

            It "Should update feed CbcFeed - exception" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_feeds.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 500
                            Content    = ""
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["FeedInfo"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).provider_url -eq "test2.com" -and
                    ($Body | ConvertFrom-Json).summary -eq "test" -and
                    ($Body | ConvertFrom-Json).category -eq "test" -and
                    ($Body | ConvertFrom-Json).alertable -eq $false
                }
                { Set-CbcFeed -Feed $feed -Name "My Feed" -ProviderUrl "test2.com" -Summary test -Category test -Alertable $false -ErrorAction Stop } | Should -Throw
            }
        }
    }
}
