InModuleScope PSCarbonBlackCloud {
    Describe "Invoke-CBCRequest" {
        BeforeAll {
            $TestServerObject1 = @{
                Uri   = "https://test.adasdagf/"
                Org   = "test"
                Token = "test"
            }

            $TestServerObject2 = @{
                Uri   = "https://test02.adasdagf/"
                Org   = "test"
                Token = "test"
            }

            $TestServerObject3 = @{
                Uri   = "https://test03.adasdagf/"
                Org   = "tes331t"
                Token = "test"
            }
        }

        BeforeEach {
            $CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
        }
        Context "On empty current connections" {
            It "Should return error" {
                $Endpoint = "DevicesAPI"
                $EndpointMethod = "SpecDevInfo"
                $Method = "Get"
                $ID = 1

                {Invoke-CBCRequest -Endpoint $Endpoint -EndpointMethod $EndpointMethod -Method $Method -ID $ID} | Should -Throw "There are no current connections!"
                
            } 
        }
        Context "On one current connection" {
            It "Makes a request with one current connection" {
                $Endpoint = "DevicesAPI"
                $EndpointMethod = "SpecDevInfo"
                $Method = "Get"
                $ID = 1

                $CBC_CONFIG.currentConnections.Add($TestServerObject1)
                $fullUrl = $TestServerObject1.Uri + [string]::Format($CBC_CONFIG.endpoints[$Endpoint][$EndpointMethod], $TestServerObject1.Org, $ID)
                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                } -ParameterFilter { $Uri -eq $fullUrl }
                $response = Invoke-CBCRequest -Endpoint $Endpoint -EndpointMethod $EndpointMethod -Method $Method -ID $ID
                $response.StatusCode | Should -be 200
            }

            It "Should return error" {
                $Endpoint = "DevicesAPI"
                $EndpointMethod = "SpecDevInfo"
                $Method = "Get"
                $ID = 1

                $CBC_CONFIG.currentConnections.Add($TestServerObject1)
                $fullUrl = $TestServerObject1.Uri + [string]::Format($CBC_CONFIG.endpoints[$Endpoint][$EndpointMethod], $TestServerObject1.Org, $ID)
                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    Throw "Exception"
                } -ParameterFilter { $Uri -eq $fullUrl }

                {Invoke-CBCRequest -Endpoint $Endpoint -EndpointMethod $EndpointMethod -Method $Method -ID $ID } | Should -Throw "Cannot reach the server!"
            }
        }

        Context "On two current connection" {
            It "Makes a request with one current connection" {
                $Endpoint1 = "DevicesAPI"
                $EndpointMethod1 = "SpecDevInfo"
                $Method1 = "Get"
                $ID1 = 1

                $CBC_CONFIG.currentConnections.Add($TestServerObject1)
                $CBC_CONFIG.currentConnections.Add($TestServerObject2)
                
                $fullUrl1 = $TestServerObject1.Uri + [string]::Format($CBC_CONFIG.endpoints[$Endpoint1][$EndpointMethod1], $TestServerObject1.Org, $ID1)
                $fullUrl2 = $TestServerObject2.Uri + [string]::Format($CBC_CONFIG.endpoints[$Endpoint1][$EndpointMethod1], $TestServerObject2.Org, $ID1)
                
                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                } -ParameterFilter { $Uri -eq $fullUrl1 }

                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                } -ParameterFilter { $Uri -eq $fullUrl2 }

                $response = Invoke-CBCRequest -Endpoint $Endpoint1 -EndpointMethod $EndpointMethod1 -Method $Method1 -ID $ID1

                $response.StatusCode | Should -be @(200, 200)
               
            }
        }
    } 
}