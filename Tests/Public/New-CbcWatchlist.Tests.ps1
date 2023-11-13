using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
    Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "New-CbcWatchlist" {
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

            It "Should create watchlist" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
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

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/watchlist.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Subscribe"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).description -eq "Example Feed" -and
                    ($Body | ConvertFrom-Json).alerts_enabled -eq $true -and
                    ($Body | ConvertFrom-Json).classifier.value -eq "ABCDEFGHIJKLMNOPQRSTUVWX"
                }

                $Watchlist = New-CbcWatchlist -FeedId ABCDEFGHIJKLMNOPQRSTUVWX 

                $Watchlist.Count | Should -Be 1
                $Watchlist[0].Name | Should -Be "My Feed"
                $Watchlist[0].Server | Should -Be $s1
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
            }

            It "Should create watchlist for specific connections" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
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

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/watchlist.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Subscribe"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).description -eq "Example Feed" -and
                    ($Body | ConvertFrom-Json).alerts_enabled -eq $true -and
                    ($Body | ConvertFrom-Json).classifier.value -eq "ABCDEFGHIJKLMNOPQRSTUVWX"
                }

                $Watchlist = New-CbcWatchlist -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX" -Server $s1

                $Watchlist.Count | Should -Be 1
                $Watchlist[0].Name | Should -Be "My Feed"
                $Watchlist[0].Server | Should -Be $s1
            }

            It "Should create watchlist for all connections" {
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
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/watchlist.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Subscribe"] -and
                    $Method -eq "POST" -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).description -eq "Example Feed" -and
                    ($Body | ConvertFrom-Json).alerts_enabled -eq $true -and
                    ($Body | ConvertFrom-Json).classifier.value -eq "ABCDEFGHIJKLMNOPQRSTUVWX"
                }

                $Watchlist = New-CbcWatchlist -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX"

                $Watchlist.Count | Should -Be 2
                $Watchlist[0].Name | Should -Be "My Feed"
                $Watchlist[0].Server | Should -Be $s1
                $Watchlist[1].Name | Should -Be "My Feed"
                $Watchlist[1].Server | Should -Be $s2
            }

            It "Should try to create watchlist for all connections - exception" {
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
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/watchlist.json"
                        }
                    }
                    else {
                        @{
                            StatusCode = 500
                            Content    = ""
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Subscribe"] -and
                    $Method -eq "POST" -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).description -eq "Example Feed" -and
                    ($Body | ConvertFrom-Json).alerts_enabled -eq $true -and
                    ($Body | ConvertFrom-Json).classifier.value -eq "ABCDEFGHIJKLMNOPQRSTUVWX"
                }

                $Watchlist = New-CbcWatchlist -FeedId "ABCDEFGHIJKLMNOPQRSTUVWX"

                $Watchlist.Count | Should -Be 1
                $Watchlist[0].Name | Should -Be "My Feed"
                $Watchlist[0].Server | Should -Be $s1
            }

            It "Should create watchlist for CbcFeed" {
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
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/watchlist.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Subscribe"] -and
                    $Method -eq "POST" -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).description -eq "Example Feed" -and
                    ($Body | ConvertFrom-Json).alerts_enabled -eq $true -and
                    ($Body | ConvertFrom-Json).classifier.value -eq "ABCDEFGHIJKLMNOPQRSTUVWX"
                }

                $Watchlist = New-CbcWatchlist -Feed $feed1

                $Watchlist.Count | Should -Be 1
                $Watchlist[0].Name | Should -Be "My Feed"
                $Watchlist[0].Server | Should -Be $s1
            }

            It "Should create watchlist for CbcFeed - exception" {
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
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Subscribe"] -and
                    $Method -eq "POST" -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).description -eq "Example Feed" -and
                    ($Body | ConvertFrom-Json).alerts_enabled -eq $true -and
                    ($Body | ConvertFrom-Json).classifier.value -eq "ABCDEFGHIJKLMNOPQRSTUVWX"
                }

                $Watchlist = New-CbcWatchlist -Feed $feed1
                $Watchlist.Count | Should -Be 0
            }
        }
    }
}
