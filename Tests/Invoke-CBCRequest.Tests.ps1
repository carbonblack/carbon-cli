Try {
    $private = @(Get-ChildItem -Path ".\src\Private" @dotSourceParams)
}
Catch {
    Throw $_
}

ForEach ($file in @($public + $private)) {
    . $file.FullName
}

InModuleScope PSCarbonBlackCloud {
    Describe "Invoke-CBCRequest" {

        BeforeAll {

            $TestServerObject1 = @{
                Uri   = "https://defense-prod05.conferdeploy.net/"
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

        # Resetting the State of tests
        BeforeEach {
            $CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
            Disconnect-CBCServer *
        }

        It "Should return status 200" {
            
            $CBC_CONFIG.currentConnections.Add($TestServerObject1)

            Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                return @{
                    StatusCode = 200
                }
            } -ParameterFilter { 
                $Uri -match "https://defense-prod05.conferdeploy.net/appservices/v6/orgs/test/devices/123"
            }
            $url = "appservices/v6/orgs/{0}/devices/{1}"

            $response = Invoke-CBCRequest -Uri $url -Method "Get" -Params @("123")

            $response | Should -Not -Be $null
        }

    }
}