using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Get-CbcProcessDetails" {
	Context "When using single connections " {
        BeforeEach {
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
            $global:called = $false
        }
        Context "When using the 'Id' parameter set" {
            It "Should set the HTTP Request Body accordingly" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/start_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ProcessDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/results_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ProcessDetails"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $process = Get-CbcProcessDetails -Id "d266ac1613e011ee9c5d536794589aaa:82a39c64-3e31-452d-6440-716d68040aaa" -Server $s1
                $process[0] | Should -Be CbcProcessDetails
                $process.Count | Should -Be 1
            }

            It "Should return CbcJob object" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/start_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ProcessDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/results_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ProcessDetails"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $job = Get-CbcProcessDetails -Id "d266ac1613e011ee9c5d536794589aaa:82a39c64-3e31-452d-6440-716d68040aaa" -Server $s1 -AsJob
                $job.Status | Should -Be "Running"
                $job.Type | Should -Be "process_details"
                $job | Should -Be CbcJob
            }

            It "Should fail with exception" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 400
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/start_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ProcessDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1
                }

                {Get-CbcProcessDetails -Id "d266ac1613e011ee9c5d536794589aaa:82a39c64-3e31-452d-6440-716d68040aaa" -ErrorAction Stop} | Should -Throw 
                $Error[0] | Should -BeLike "Cannot create process details job for*"
            }
        }
    }
    Context "When using multiple connections " {
        BeforeEach {
            $global:DefaultCbcServers = [System.Collections.ArrayList]@()
            $Uri = "https://t.te1/"
            $Org = "test1"
            $secureToken = "test1" | ConvertTo-SecureString -AsPlainText
            $s1 = [CbcServer]::new($Uri, $Org, $secureToken)
            $global:DefaultCbcServers.Add($s1) | Out-Null
            $Uri2 = "https://t.te2/"
            $Org2 = "test2"
            $secureToken2 = "test2" | ConvertTo-SecureString -AsPlainText
            $s2 = [CbcServer]::new($Uri2, $Org2, $secureToken2)
            $global:DefaultCbcServers.Add($s2) | Out-Null
        }
        Context "When using the 'Id' parameter set" {
            It "Should set the HTTP Request Body accordingly" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/start_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ProcessDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/results_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ProcessDetails"]["Results"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                $processes = Get-CbcProcessDetails -Id "d266ac1613e011ee9c5d536794589aaa:82a39c64-3e31-452d-6440-716d68040aaa"
                $processes[0] | Should -Be CbcProcessDetails
                $processes.Count | Should -Be 2
            }
        }
    }
}
