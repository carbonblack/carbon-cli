using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Get-CbcObservation" {
	Context "When using single connections " {
        Context "When using the 'IncludeExclude' parameter set" {
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
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $observations = Get-CbcObservation -Include @{"alert_category" = "OBSERVED"}

                $observations[0].DeviceId | Should -Be 17482451
                $observations[0].AlertCategory | Should -Be "OBSERVED"
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
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                    $Body -eq @{
                        criteria = @{
                            observation_id = "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
                        }
                        rows = 500
                    }
                }

                $observations = Get-CbcObservation -Id "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
                $observations[0].ObservationId | Should -Be "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
            }
        }
    }
}
