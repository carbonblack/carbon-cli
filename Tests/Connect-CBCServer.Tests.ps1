Describe "Connect-CBCServer" {

    Context "When `-Menu` arg is invoked" {

        BeforeDiscovery {
            Disconnect-CBCServer *
        }

        Context "On empty Menu" {

            BeforeAll {
                $emptyArray = [System.Collections.ArrayList]@()
                Set-Variable CBC_DEFAULT_SERVERS -Value $emptyArray -Scope Global
            }

            It "Throws an error" {
                { Connect-CBCServer -Menu } | Should -Throw "There are no default servers available!"
            }

        }
        
        Context "On single active connection" {

            BeforeEach {
                Disconnect-CBCServer *
            }
            
            Context "On single server" {
    
                BeforeAll {
                    $MockServerObject = @{
                        Server = "https://defense-dev01.cbdtest.io/"
                        Org = "ABC"
                        Token = "CDE"
                    }
                    $emptyArray = [System.Collections.ArrayList]@()
                    Set-Variable CBC_DEFAULT_SERVERS -Value $emptyArray -Scope Global
                    $CBC_DEFAULT_SERVERS.Add($MockServerObject) | Out-Null
                }
        
                It "Returns the server object" {
                    Mock -ModuleName "PSCarbonBlackCloud"  -CommandName "Read-Host" -MockWith {
                        return "1"
                    };
                    $result = Connect-CBCServer -Menu
                    $result | Should -Be $MockServerObject
                    $CBC_CURRENT_CONNECTIONS[0] | Should -Be $MockServerObject
                    $CBC_CURRENT_CONNECTIONS.Count | Should -Be 1
                }
        
                It "Throws an error" {
                    Mock -ModuleName "PSCarbonBlackCloud"  -CommandName "Read-Host" -MockWith {
                        return "2"
                    };

                    { Connect-CBCServer -Menu } | Should -Throw "There is no default server with that index"
                    $CBC_CURRENT_CONNECTIONS | Should -Be $null
                    $CBC_CURRENT_CONNECTIONS.Count | Should -Be 0
                }
    
            }
    
            Context "On multiple servers" {

                BeforeAll {
                    $MockServerObject = @{
                        Server = "https://defense-dev01.cbdtest.io/"
                        Org = "ABC"
                        Token = "CDE"
                    }
                    $MockServerObject2 = @{
                        Server = "https://defense-dev01.cbdtest.io/"
                        Org = "ABC"
                        Token = "CDE"
                    }
                    $emptyArray = [System.Collections.ArrayList]@()
                    Set-Variable CBC_DEFAULT_SERVERS -Value $emptyArray -Scope Global
                    $CBC_DEFAULT_SERVERS.Add($MockServerObject) | Out-Null
                    $CBC_DEFAULT_SERVERS.Add($MockServerObject2) | Out-Null
                }
        
                It "Returns the server object" {
                    Mock -ModuleName "PSCarbonBlackCloud"  -CommandName "Read-Host" -MockWith {
                        return "1"
                    };
                    $result = Connect-CBCServer -Menu
                    $result | Should -Be $MockServerObject
                    $CBC_CURRENT_CONNECTIONS[0] | Should -Be $MockServerObject
                    $CBC_CURRENT_CONNECTIONS.Count | Should -Be 1
                    
                }

                It "Returns the second server object" {
                    Mock -ModuleName "PSCarbonBlackCloud"  -CommandName "Read-Host" -MockWith {
                        return "2"
                    };
                    $result = Connect-CBCServer -Menu
                    $result | Should -Be $MockServerObject2
                    $CBC_CURRENT_CONNECTIONS[0] | Should -Be $MockServerObject2
                    $CBC_CURRENT_CONNECTIONS.Count | Should -Be 1
                }
        
                It "Throws an error" {
                    Mock -ModuleName "PSCarbonBlackCloud"  -CommandName "Read-Host" -MockWith {
                        return "0"
                    };
                    { Connect-CBCServer -Menu } | Should -Throw "There is no default server with that index"
                    $CBC_CURRENT_CONNECTIONS | Should -Be $null
                    $CBC_CURRENT_CONNECTIONS.Count | Should -Be 0
                }
    
            }

        }

    }

}