using module ..\..\CarbonCLI\CarbonCLI.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name CarbonCLI -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\CarbonCLI\CarbonCLI.psm1 -Force
}

AfterAll {
    Remove-Module -Name CarbonCLI -Force
}

Describe "Set-CbcWatchlist" {
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

            It "Should update watchlist" {
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

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/watchlist.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Watchlist"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).description -eq "xx" -and
                    ($Body | ConvertFrom-Json).alerts_enabled -eq $true -and
                    ($Body | ConvertFrom-Json).tags_enabled -eq $false -and
                    ($Body | ConvertFrom-Json).alert_classification_enabled -eq $true
                }

                $watchlist = Set-CbcWatchlist -Id R4cMgFIhRaakgk749MRr6Q -Name "My Feed" -Description "xx" -AlertsEnabled $true -TagsEnabled $false -AlertClassificationEnabled $true
                $watchlist.Count | Should -Be 1
			    $watchlist[0].Server | Should -Be $s1
			    $watchlist[0].Name | Should -Be "My Feed"
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
                $watchlist = [CbcWatchlist]::new(
                    "ABCDEFGHIJKLMNOPQRSTUVWX",
                    "My Watchlist",
                    "Example Watchlist",
                    $true,
                    $true,
                    $true,
                    "ABCDEFGHIJKLMNOPQRSTUVWX",
                    $s1
                )
            }

            It "Should update watchlist for specific connections" {
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

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/watchlist.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Watchlist"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).description -eq "xx" -and
                    ($Body | ConvertFrom-Json).alerts_enabled -eq $true -and
                    ($Body | ConvertFrom-Json).tags_enabled -eq $false -and
                    ($Body | ConvertFrom-Json).alert_classification_enabled -eq $true
                }

                $watchlist = Set-CbcWatchlist -Id R4cMgFIhRaakgk749MRr6Q -Name "My Feed" -Description "xx" -AlertsEnabled $true -TagsEnabled $false -AlertClassificationEnabled $true -Server $s1
                $watchlist.Count | Should -Be 1
			    $watchlist[0].Server | Should -Be $s1
			    $watchlist[0].Name | Should -Be "My Feed"
            }

            It "Should update watchlist for all connections" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/all_watchlists.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Watchlist"]["Search"] -and
                    $Method -eq "GET"
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/watchlist.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Watchlist"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).description -eq "xx" -and
                    ($Body | ConvertFrom-Json).alerts_enabled -eq $true -and
                    ($Body | ConvertFrom-Json).tags_enabled -eq $false -and
                    ($Body | ConvertFrom-Json).alert_classification_enabled -eq $true
                }

                $watchlist = Set-CbcWatchlist -Id R4cMgFIhRaakgk749MRr6Q -Name "My Feed" -Description "xx" -AlertsEnabled $true -TagsEnabled $false -AlertClassificationEnabled $true
                $watchlist.Count | Should -Be 2
			    $watchlist[0].Server | Should -Be $s1
			    $watchlist[0].Name | Should -Be "My Feed"
                $watchlist[1].Server | Should -Be $s2
			    $watchlist[1].Name | Should -Be "My Feed"
            }

            It "Should try to update watchlist for all connections - exception" {
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

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 500
                        Content = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Watchlist"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).description -eq "xx" -and
                    ($Body | ConvertFrom-Json).alerts_enabled -eq $true -and
                    ($Body | ConvertFrom-Json).tags_enabled -eq $false -and
                    ($Body | ConvertFrom-Json).alert_classification_enabled -eq $true
                }
                { Set-CbcWatchlist -Id R4cMgFIhRaakgk749MRr6Q -Name "My Feed" -Description "xx" -AlertsEnabled $true -TagsEnabled $false -AlertClassificationEnabled $true -ErrorAction Stop } | Should -Throw
            }

            It "Should update watchlist - CbcWatchlist" {
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

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/watchlist.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Watchlist"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).description -eq "xx" -and
                    ($Body | ConvertFrom-Json).alerts_enabled -eq $true -and
                    ($Body | ConvertFrom-Json).tags_enabled -eq $false -and
                    ($Body | ConvertFrom-Json).alert_classification_enabled -eq $true
                }

                $watchlist = Set-CbcWatchlist -Watchlist $watchlist -Name "My Feed" -Description "xx" -AlertsEnabled $true -TagsEnabled $false -AlertClassificationEnabled $true
                $watchlist.Count | Should -Be 1
			    $watchlist[0].Server | Should -Be $s1
			    $watchlist[0].Name | Should -Be "My Feed"
            }

            It "Should update watchlist CbcWatchlist - exception" {
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

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 500
                            Content    = ""
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Watchlist"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).description -eq "xx" -and
                    ($Body | ConvertFrom-Json).alerts_enabled -eq $true -and
                    ($Body | ConvertFrom-Json).tags_enabled -eq $false -and
                    ($Body | ConvertFrom-Json).alert_classification_enabled -eq $true
                }
                { Set-CbcWatchlist -Watchlist $watchlist -Name "My Feed" -Description "xx" -AlertsEnabled $true -TagsEnabled $false -AlertClassificationEnabled $true -ErrorAction Stop } | Should -Throw
            }
        }
    }
}
