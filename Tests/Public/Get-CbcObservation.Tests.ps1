using module ..\..\src\CarbonCLI.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name CarbonCLI -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\CarbonCLI.psm1 -Force
}

AfterAll {
	Remove-Module -Name CarbonCLI -Force
}

Describe "Get-CbcObservation" {
	Context "When using single connections " {
        Context "When using the 'IncludeExclude' parameter set" {
            BeforeAll {
                $Uri1 = "https://t.te1/"
                $Org1 = "test1"
                $secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
                $s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
                $global:DefaultCbcServers = [System.Collections.ArrayList]@()
                $global:DefaultCbcServers.Add($s1) | Out-Null
                $global:called = $false
            }

            It "Should set the HTTP Request Body accordingly" {
                $global:called = $false
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    if (!$global:called) {
                        $global:called = $true
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job_running.json"
                        }
                    }
                    else {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }
                $Include = @{"alert_category" = @("OBSERVED")}
                $Exclude = @{"observation_type" = @("CB_ANALYTICS")}
                $observations = Get-CbcObservation -Include $Include -Exclude $Exclude  -Server $s1

                $observations[0].DeviceId | Should -Be 17482451
                $observations[0].AlertCategory | Should -Be "OBSERVED"
                $observations[0].Server | Should -Be $s1
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
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).rows -eq 500 -and
                    ($Body | ConvertFrom-Json).criteria.observation_id -eq "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $observations = Get-CbcObservation -Id "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
                $observations[0].ObservationId | Should -Be "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
            }

            It "Should set the HTTP Request Body accordingly - Alert" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).rows -eq 500 -and
                    ($Body | ConvertFrom-Json).criteria.alert_id -eq "1"
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
					@{
						StatusCode = 200
						Content    = Get-Content "$ProjectRoot/Tests/resources/alerts_api/all_alerts.json"
					}
				} -ParameterFilter {
					$Endpoint -eq $global:CBC_CONFIG.endpoints["Alerts"]["Search"] -and
					$Method -eq "POST" -and
					$Server -eq $s1
				}

                $observations = Get-CbcAlert -Id "1" | Get-CbcObservation
                $observations[0] | Should -Be CbcObservation
            }

            It "Should set the filter parameters as criteria accordingly" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).rows -eq 500 -and
                    ($Body | ConvertFrom-Json).criteria.alert_id -eq "b01dad69-09e8-71ba-6542-60f5a8d58030" -and
                    ($Body | ConvertFrom-Json).criteria.observation_type -eq "CB_ANALYTICS" -and
                    ($Body | ConvertFrom-Json).criteria.event_type -eq "childproc" -and
                    ($Body | ConvertFrom-Json).criteria.device_id -eq "16801738"
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $observations = Get-CbcObservation -AlertId "b01dad69-09e8-71ba-6542-60f5a8d58030" -ObservationType "CB_ANALYTICS" -EventType "childproc" -DeviceId "16801738"
                $observations[0] | Should -Be CbcObservation
            }

            It "Should set the query parameter accordingly" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).rows -eq 500 -and
                    ($Body | ConvertFrom-Json).query -eq "alert_id:b01dad69-09e8-71ba-6542-60f5a8d58030"
                }

                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $observations = Get-CbcObservation -Query "alert_id:b01dad69-09e8-71ba-6542-60f5a8d58030"
                $observations[0] | Should -Be CbcObservation
            }

            It "Should return job object" {
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).rows -eq 500 -and
                    ($Body | ConvertFrom-Json).criteria.observation_id -eq "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
                }

                $job = Get-CbcObservation -Id "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e" -AsJob
                $job[0].Status | Should -Be "Running"
                $job[0].Type | Should -Be "observation_search"
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
                Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                    @{
                        StatusCode = 500
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    ($Body | ConvertFrom-Json).rows -eq 500 -and
                    ($Body | ConvertFrom-Json).criteria.observation_id -eq "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
                }

                {Get-CbcObservation -Id "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e" -ErrorAction Stop} | Should -Throw
                $Error[0] | Should -BeLike "Cannot create observation_search*"
            }
        }
    }
}
