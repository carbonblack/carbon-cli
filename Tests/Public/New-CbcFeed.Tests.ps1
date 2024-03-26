using module ..\..\CarbonCLI\CarbonCLI.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name CarbonCLI -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\CarbonCLI\CarbonCLI.psm1 -Force
}

AfterAll {
    Remove-Module -Name CarbonCLI -Force
}

Describe "New-CbcFeed" {
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

            It "Should create feed" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/create_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).feedinfo.name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).feedinfo.provider_url -eq "test.com" -and
                    ($Body | ConvertFrom-Json).feedinfo.summary -eq "test" -and
                    ($Body | ConvertFrom-Json).feedinfo.category -eq "test" -and
                    ($Body | ConvertFrom-Json).feedinfo.alertable -eq $true
                }

                $Feed = New-CbcFeed -Name "My Feed" -ProviderUrl "test.com" -Summary "test" -Category "test" -Alertable $true

                $Feed.Count | Should -Be 1
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
            }

            It "Should not create feed" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 500
                        Content    = ""
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).feedinfo.name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).feedinfo.provider_url -eq "test.com" -and
                    ($Body | ConvertFrom-Json).feedinfo.summary -eq "test" -and
                    ($Body | ConvertFrom-Json).feedinfo.category -eq "test" -and
                    ($Body | ConvertFrom-Json).feedinfo.alertable -eq $true
                }

                {New-CbcFeed -Name "My Feed" -ProviderUrl "test.com" -Summary "test" -Category "test" -Alertable $true -ErrorAction Stop} | Should -Throw
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

            It "Should create feed for specific connections" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/create_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).feedinfo.name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).feedinfo.provider_url -eq "test.com" -and
                    ($Body | ConvertFrom-Json).feedinfo.summary -eq "test" -and
                    ($Body | ConvertFrom-Json).feedinfo.category -eq "test" -and
                    ($Body | ConvertFrom-Json).feedinfo.alertable -eq $true
                }

                $Feed = New-CbcFeed -Name "My Feed" -ProviderUrl "test.com" -Summary "test" -Category "test" -Alertable $true -Server $s1

                $Feed.Count | Should -Be 1
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
            }

            It "Should create feed for all connections" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/create_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "POST" -and
                    ($Body | ConvertFrom-Json).feedinfo.name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).feedinfo.provider_url -eq "test.com" -and
                    ($Body | ConvertFrom-Json).feedinfo.summary -eq "test" -and
                    ($Body | ConvertFrom-Json).feedinfo.category -eq "test" -and
                    ($Body | ConvertFrom-Json).feedinfo.alertable -eq $true
                }

                $Feed = New-CbcFeed -Name "My Feed" -ProviderUrl "test.com" -Summary "test" -Category "test" -Alertable $true

                $Feed.Count | Should -Be 2
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
                $Feed[1].Name | Should -Be "My Feed"
                $Feed[1].Server | Should -Be $s2
            }
            It "Should create feed for all connections with custom body" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/create_feed.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Feed"]["Search"] -and
                    $Method -eq "POST" -and
                    ($Body | ConvertFrom-Json).feedinfo.name -eq "My Feed" -and
                    ($Body | ConvertFrom-Json).feedinfo.provider_url -eq "test.com" -and
                    ($Body | ConvertFrom-Json).feedinfo.summary -eq "test" -and
                    ($Body | ConvertFrom-Json).feedinfo.category -eq "test" -and
                    ($Body | ConvertFrom-Json).feedinfo.alertable -eq $true
                }
                $RequestBody = @{
                    "feedinfo" = @{
                        "name" = "My Feed"
                        "provider_url" = "test.com"
                        "summary" = "test"
                        "category" = "test"
                        "alertable" = $true
                    }
                    "reports" = @()
                }
                $Feed = New-CbcFeed -Body $RequestBody

                $Feed.Count | Should -Be 2
                $Feed[0].Name | Should -Be "My Feed"
                $Feed[0].Server | Should -Be $s1
                $Feed[1].Name | Should -Be "My Feed"
                $Feed[1].Server | Should -Be $s2
            }
        }
    }
}
