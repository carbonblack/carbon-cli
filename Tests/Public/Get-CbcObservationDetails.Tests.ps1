using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Get-CbcObservationDetails" {
	Context "When using single connections " {
        BeforeEach {
            $Uri = "https://t.te1/"
            $Org = "test1"
            $secureToken = "test1" | ConvertTo-SecureString -AsPlainText
            $s1 = [CbcServer]::new($Uri, $Org, $secureToken)
            $global:DefaultCbcServers = [System.Collections.ArrayList]@()
            $global:DefaultCbcServers.Add($s1) | Out-Null
        }
        Context "When using the 'Id' parameter set" {
            It "Should set the HTTP Request Body accordingly" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $observation = Get-CbcObservationDetails -Id "d266ac1613e011ee9c5d536794589aaa:82a39c64-3e31-452d-6440-716d68040aaa"
                $observation.DeviceId | Should -Be 11412673
            }
        }
        Context "When using the 'AlertId' parameter set" {
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
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1 -and
                    $Body -eq @{
                        criteria = @{
                            alert_id = "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
                        }
                        rows = 500
                    }
                }

                $observations = Get-CbcObservationDetails -AlertId "82a39c64-3e31-452d-6440-716d68040524"
                $observations[0].AlertId[0] | Should -Be "82a39c64-3e31-452d-6440-716d68040524"
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
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["Results"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                $observation = Get-CbcObservationDetails -Id "d266ac1613e011ee9c5d536794589aaa:82a39c64-3e31-452d-6440-716d68040aaa"
                $observation[0].DeviceId | Should -Be 11412673
                $observation.Count | Should -Be 2
            }
        }
        Context "When using the 'AlertId' parameter set" {
            It "Should set the HTTP Request Body accordingly" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["Results"] + "?start=0&rows=" -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2) -and
                    $Body -eq @{
                        criteria = @{
                            alert_id = "8fbccc2da75f11ed937ae3cb089984c6:be6ff259-88e3-6286-789f-74defa192d2e"
                        }
                        rows = 500
                    }
                }

                $observations = Get-CbcObservationDetails -AlertId "82a39c64-3e31-452d-6440-716d68040524"
                $observations[0].AlertId[0] | Should -Be "82a39c64-3e31-452d-6440-716d68040524"
                $observations.Count | Should -Be 2
            }
        }
    }
}
