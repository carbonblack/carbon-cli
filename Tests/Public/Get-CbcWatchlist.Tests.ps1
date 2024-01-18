using module ..\..\src\CarbonCLI.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name CarbonCLI -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\src\CarbonCLI.psm1 -Force
}

AfterAll {
    Remove-Module -Name CarbonCLI -Force
}

Describe "Get-CbcWatchlist" {
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

            It "Should return all watchlists" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_watchlists.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Watchlist"]["Search"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $Watchlist = Get-CbcWatchlist

                $Watchlist.Count | Should -Be 2
                $Watchlist[0].Name | Should -Be "My Watchlist"
                $Watchlist[0].Server | Should -Be $s1
                $Watchlist[1].Name | Should -Be "My Other Watchlist"
                $Watchlist[1].Server | Should -Be $s1
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

            It "Should return all watchlists for all connections" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_watchlists.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Watchlist"]["Search"] -and
                    $Method -eq "GET"
                }

                $Watchlist = Get-CbcWatchlist

                $Watchlist.Count | Should -Be 4
                $Watchlist[0].Name | Should -Be "My Watchlist"
                $Watchlist[0].Server | Should -Be $s1
                $Watchlist[1].Name | Should -Be "My Other Watchlist"
                $Watchlist[1].Server | Should -Be $s1
                $Watchlist[2].Name | Should -Be "My Watchlist"
                $Watchlist[2].Server | Should -Be $s2
                $Watchlist[3].Name | Should -Be "My Other Watchlist"
                $Watchlist[3].Server | Should -Be $s2
            }

            It "Should return all watchlists for all connections - exception" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 400
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Watchlist"]["Search"] -and
                    $Method -eq "GET"
                }

                { Get-CbcWatchlist -ErrorAction Stop } | Should -Throw
            }

            It "Should return all watchlists for specific connection" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_watchlists.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Watchlist"]["Search"] -and
                    $Method -eq "GET"
                }

                $Watchlist = Get-CbcWatchlist -Server $s1

                $Watchlist.Count | Should -Be 2
                $Watchlist[0].Name | Should -Be "My Watchlist"
                $Watchlist[0].Server | Should -Be $s1
                $Watchlist[1].Name | Should -Be "My Other Watchlist"
                $Watchlist[1].Server | Should -Be $s1
            }

            It "Should return all watchlists for all connections - specific name" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_watchlists.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Watchlist"]["Search"] -and
                    $Method -eq "GET"
                }

                $Watchlist = Get-CbcWatchlist -Name "My Watchlist"

                $Watchlist.Count | Should -Be 2
                $Watchlist[0].Name | Should -Be "My Watchlist"
                $Watchlist[0].Server | Should -Be $s1
                $Watchlist[1].Name | Should -Be "My Watchlist"
                $Watchlist[1].Server | Should -Be $s2
            }

            It "Should return all watchlists for all connections - specific id" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_watchlists.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Watchlist"]["Search"] -and
                    $Method -eq "GET"
                }

                $Watchlist = Get-CbcWatchlist -Id "5LKpHr2SHiaE2QprfPhQ"

                $Watchlist.Count | Should -Be 2
                $Watchlist[0].Name | Should -Be "My Watchlist"
                $Watchlist[0].Server | Should -Be $s1
                $Watchlist[1].Name | Should -Be "My Watchlist"
                $Watchlist[1].Server | Should -Be $s2
            }
        }
    }
}
