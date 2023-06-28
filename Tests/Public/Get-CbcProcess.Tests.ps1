using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Get-CbcProcess" {
	Context "When using single connections " {
        Context "When using the 'IncludeExclude' parameter set" {
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
                $global:called = $false
            }

            It "Should set the HTTP Request Body accordingly" {
                $global:called = $false
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/start_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Processes"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if (!$global:called) {
                        $global:called = $true
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/results_search_job_running.json"
                        }
                    }
                    else {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/results_search_job.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Processes"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }
                $Include = @{"device_name" = @("alabala")}
                $Exclude = @{"device_os" = @("WINDOWS")}
                $processes = Get-CbcProcess -Include $Include -Exclude $Exclude -Server $s1

                $processes.Count | Should -Be 1
                $processes[0].Server | Should -Be $s1
            }
        }
        Context "When using the 'Id' parameter set" {
            BeforeAll {
                $Uri = "https://t.te1/"
                $Org = "test1"
                $secureToken = "test1" | ConvertTo-SecureString -AsPlainText
                $s1 = [CbcServer]::new($Uri, $Org, $secureToken)
                $global:DefaultCbcServers = [System.Collections.ArrayList]@()
			    $global:DefaultCbcServers.Add($s1) | Out-Null
            }
            It "Should set the HTTP Request Body accordingly" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/start_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Processes"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).rows -eq 500 -and
                    ($Body | ConvertFrom-Json).criteria.process_guid -eq "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/results_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Processes"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $processes = Get-CbcProcess -Id "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
                $processes[0] | Should -Be CbcProcess
                $processes.Count | Should -Be 1
            }

            It "Should return job object" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/start_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Processes"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).rows -eq 500 -and
                    ($Body | ConvertFrom-Json).criteria.process_guid -eq "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
                }

                $job = Get-CbcProcess -Id "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e" -AsJob
                $job[0].Status | Should -Be "Running"
                $job[0].Type | Should -Be "process_search"
                $job | Should -Be CbcJob
            }
        }
    
        Context "When using the 'Id' parameter set - exceptions" {
            BeforeAll {
                $Uri = "https://t.te1/"
                $Org = "test1"
                $secureToken = "test1" | ConvertTo-SecureString -AsPlainText
                $s1 = [CbcServer]::new($Uri, $Org, $secureToken)
                $global:DefaultCbcServers = [System.Collections.ArrayList]@()
			    $global:DefaultCbcServers.Add($s1) | Out-Null
            }
            It "Should fail upon creating job" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 500
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/start_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Processes"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).rows -eq 500 -and
                    ($Body | ConvertFrom-Json).criteria.process_guid -eq "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
                }

                {Get-CbcProcess -Id "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e" -ErrorAction Stop} | Should -Throw
                $Error[0] | Should -BeLike "Cannot create process search*"
            }
        }
    }
}
