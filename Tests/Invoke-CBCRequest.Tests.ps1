Describe "Invoke-CBCRequest" {   
    
    BeforeEach {
        $CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
    }

    InModuleScope PSCarbonBlackCloud {
        
        Context "Endpoint Formatting" {

            It "Should format the url correctly" {
            
                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                } -ParameterFilter { 
                    $Uri -match "https://test.adasdagf/appservices/v6/orgs/test/devices/123"
                    $Method -eq "Get"
                    $Body -eq @{test = "test" }
                    $Headers -match @{
                        "X-AUTH-TOKEN" = "test"
                        "Content-Type" = "application/json"
                        "User-Agent"   = "PSCarbonBlackCloud"
                    }
                }

                $endpoint = $CBC_CONFIG.endpoints["Devices"]["Search"]
                $response = Invoke-CBCRequest -CBCServer @{
                    Uri   = "https://test.adasdagf/"
                    Org   = "test"
                    Token = "test"
                } -Endpoint $endpoint -Method Get -Params @(123) -Body @{test = "test" }
    
                $response.StatusCode | Should -Be 200

            }

        }
        
    }

}
