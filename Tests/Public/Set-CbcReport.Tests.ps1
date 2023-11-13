using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
    Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
    Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Set-CbcReport" {
    Context "When using the 'default' parameter set" {
        Context "When using one connection" {
            BeforeAll {
                $Uri1 = "https://t.te1/"
                $Org1 = "test1"
                $secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
                
			    $s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
                $global:DefaultCbcServers = [System.Collections.ArrayList]@()
                $global:DefaultCbcServers.Add($s1) | Out-Null
                $report = [CbcReport]::new(
                    "xxx",
                    "yara",
                    "description",
                    5,
                    "google.com",
                    @(),
                    "visible",
                    "ABCDEFGHIJKLMNOPQRSTUVWX1",
                    $s1
                )
            }

            It "Should update report" {
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

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/update_report.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).title -eq "My Report" -and
                    ($Body | ConvertFrom-Json).description -eq "test" -and
                    ($Body | ConvertFrom-Json).severity -eq 7
                }
                $report = Set-CbcReport -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -Id 1 -Title "My Report" -Description test -Severity 7
                $report.Count | Should -Be 1
			    $report[0].Server | Should -Be $s1
			    $report[0].Title | Should -Be "My Report"
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
                $report = [CbcReport]::new(
                    "xxx",
                    "yara",
                    "description",
                    5,
                    "google.com",
                    @(),
                    "visible",
                    "ABCDEFGHIJKLMNOPQRSTUVWX1",
                    $s1
                )
            }

            It "Should update report for specific connections" {
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

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/update_report.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).title -eq "My Report" -and
                    ($Body | ConvertFrom-Json).description -eq "test" -and
                    ($Body | ConvertFrom-Json).severity -eq 7
                }
                $report = Set-CbcReport -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -Id 1 -Title "My Report" -Description test -Severity 7 -Server $s1
                $report.Count | Should -Be 1
			    $report[0].Server | Should -Be $s1
			    $report[0].Title | Should -Be "My Report"
            }

            It "Should update report for all connections" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/reports.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "GET"
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/update_report.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Body | ConvertFrom-Json).title -eq "My Report" -and
                    ($Body | ConvertFrom-Json).description -eq "test" -and
                    ($Body | ConvertFrom-Json).severity -eq 7
                }
                $report = Set-CbcReport -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -Id 1 -Title "My Report" -Description test -Severity 7
                $report.Count | Should -Be 2
			    $report[0].Server | Should -Be $s1
			    $report[0].Title | Should -Be "My Report"
                $report[1].Server | Should -Be $s2
			    $report[1].Title | Should -Be "My Report"
            }

            It "Should try to update report for all connections - exception" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/reports.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Search"] -and
                    $Method -eq "GET"
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/update_report.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Body | ConvertFrom-Json).title -eq "My Report" -and
                    ($Body | ConvertFrom-Json).description -eq "test" -and
                    ($Body | ConvertFrom-Json).severity -eq 7
                }
                { Set-CbcReport -FeedId ABCDEFGHIJKLMNOPQRSTUVWX -Id 1 -Title "My Report" -Description test -Severity 7 -ErrorAction Stop } | Should -Throw
            }

            It "Should update report - CbcReport" {
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

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/feed_api/update_report.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).title -eq "My Report" -and
                    ($Body | ConvertFrom-Json).description -eq "test" -and
                    ($Body | ConvertFrom-Json).severity -eq 7
                }
                $report = Set-CbcReport -Report $report -Title "My Report" -Description test -Severity 7
                $report.Count | Should -Be 1
			    $report[0].Server | Should -Be $s1
			    $report[0].Title | Should -Be "My Report"
            }

            It "Should update report CbcReport - exception" {
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

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if ($Server -eq $s1) {
                        @{
                            StatusCode = 500
                            Content    = ""
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Report"]["Details"] -and
                    $Method -eq "PUT" -and
                    ($Server -eq $s1) -and
                    ($Body | ConvertFrom-Json).title -eq "My Report" -and
                    ($Body | ConvertFrom-Json).description -eq "test" -and
                    ($Body | ConvertFrom-Json).severity -eq 7
                }
                { Set-CbcReport -Report $report -Title "My Report" -Description test -Severity 7 -ErrorAction Stop } | Should -Throw
            }
        }
    }
}
