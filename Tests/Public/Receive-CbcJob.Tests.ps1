using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Receive-CbcJob" {
	Context "When using multiple connections with a specific server" {
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
            $job = [CbcJob]::new("xxx", "observation_search", "Running", $s1)
		}

		It "Should return jobs (completed) only from the specific server" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 200
					Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
				$Server -eq $s1 -and
				$Method -eq "GET"
			}

			$observations = Receive-CbcJob -Id "xxx" -Type "observation_search" -Server @($s1)
			$observations.Count | Should -Be 1
			$observations[0].Server | Should -Be $s1
            $observations[0] | Should -Be CbcObservation
		}

        It "Should return jobs (completed) only from the specific server by job object" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 200
					Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
				$Server -eq $s1 -and
				$Method -eq "GET"
			}

			$observations = Receive-CbcJob -Job $job -Server @($s1)

			$observations.Count | Should -Be 1
			$observations[0].Server | Should -Be $s1
			$observations[0] | Should -Be CbcObservation
		}

        It "Should not return jobs (still running) only from the specific server by job object" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 200
					Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job_running.json"
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
				$Server -eq $s1 -and
				$Method -eq "GET"
			}

			{Receive-CbcJob -Job $job -Server @($s1) -ErrorAction Stop} | Should -Throw
            $Error[0] | Should -Be "Not ready to retrieve."
		}

        It "Should not return jobs due to error" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                @{
                    StatusCode = 400
                    Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job_running.json"
                }
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
				$Method -eq "GET"
			}

			{Receive-CbcJob -Job @($job) -Server $s1 -ErrorAction Stop} | Should -Throw
            $Error[0] | Should -BeLike "Cannot complete action for xxx for*"
			
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
            $job1 = [CbcJob]::new("xxx", "observation_search", "Running", $s1)
            $job2 = [CbcJob]::new("xxx", "observation_details", "Running", $s2)
		}

		It "Should return one job (the other still running)" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                if ($Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"]) {
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
				(
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -or
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["Results"]
                ) -and
				$Method -eq "GET"
			}

			$observations = Receive-CbcJob -Job @($job1, $job2)
			$observations.Count | Should -Be 1
			$observations[0].Server | Should -Be $s2
            # TODO - once we have CbcObservationDetails class - change this!
			$observations[0] | Should -Be CbcObservation
		}

        It "Should not return any jobs wrong type" {
            {Receive-CbcJob -Id "xxx" -Type "alabala" -ErrorAction Stop} | Should -Throw
            $Error[0] | Should -BeLike "Not a valid type alabala"
		}

        It "Should return jobs (completed) from one server" {
			Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                if ($Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"]) {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
                    }
                }
                else {
                    @{
                        StatusCode = 400
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
                    }
                }
			} -ParameterFilter {
				(
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -or
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["Results"]
                ) -and
				$Method -eq "GET"
			}

			$observations = Receive-CbcJob -Job @($job1, $job2)
			$observations.Count | Should -Be 1
			$observations[0].Server | Should -Be $s1
            $observations[0] | Should -Be CbcObservation
		}
	}
}