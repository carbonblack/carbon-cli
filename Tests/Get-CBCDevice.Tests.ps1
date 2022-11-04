# InModuleScope PSCarbonBlackCloud {
    Describe "Get-CBCDevice" {
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
        }

        BeforeEach {
            $CBC_CONFIG.defaultServers = [System.Collections.ArrayList]@()
            $CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
        
        }

        Context "When in All section" {
            # Context "With no connections" {
            #     It "Throws an error" {
            #         Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -Mockwith {
            #             return @{
            #                 StatusCode = 404
            #             }
            #         }
            #         {Get-CBCDevice -All} | Should -Throw
            #     }
            # }

            Context "With one connection" {
                Disconnect-CBCServer *

                $TestServerObject1 = @{
                    Uri   = "https://test.adasdagf/"
                    Org   = "test"
                    Token = "test"
                }
                
                $CBC_CONFIG.currentConnections.Add($TestServerObject1)
                Write-Host $TestServerObject1
                Write-Host $CBC_CONFIG.currentConnections.Count
                Mock Invoke-CBCRequest -ModuleName "PSCarbonBlackCloud" -MockWith {
                    Write-Host "IN THE MOCK"
                    return @{
                        $TestServerObject1.Org = [PSCustomObject]@{
                            Content = '{"StatusCode" : 200}'
                        }
                    }
                } -ParameterFilter { $Uri -eq "appservices/v6/orgs/{0}/devices/_search" }
            
                $result = Get-CBCDevice -All
                $result[0]["StatusCode"] | Should -be 200
            }
        }
    }
# }