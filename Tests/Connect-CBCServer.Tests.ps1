Describe "Connect-CBCServer" {

    Context "When in Menu section" {

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
                        Org    = "ABC"
                        Token  = "CDE"
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
        
                It "Throws an error - on '2' as input" {
                    Mock -ModuleName "PSCarbonBlackCloud"  -CommandName "Read-Host" -MockWith {
                        return "2"
                    };

                    { Connect-CBCServer -Menu } | Should -Throw "There is no default server with that index"
                    $CBC_CURRENT_CONNECTIONS | Should -Be $null
                    $CBC_CURRENT_CONNECTIONS.Count | Should -Be 0
                }

                It "Throws an error - on '0' as input" {
                    Mock -ModuleName "PSCarbonBlackCloud"  -CommandName "Read-Host" -MockWith {
                        return "0"
                    };

                    { Connect-CBCServer -Menu } | Should -Throw "There is no default server with that index"
                    $CBC_CURRENT_CONNECTIONS | Should -Be $null
                    $CBC_CURRENT_CONNECTIONS.Count | Should -Be 0
                }

                It "Throws an error - on {letter} as input" {
                    Mock -ModuleName "PSCarbonBlackCloud"  -CommandName "Read-Host" -MockWith {
                        return "ABC"
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
                        Org    = "ABC"
                        Token  = "CDE"
                    }
                    $MockServerObject2 = @{
                        Server = "https://defense-dev01.cbdtest.io/"
                        Org    = "ABC"
                        Token  = "CDE"
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

                It "Throws an error - on '2' as input" {
                    Mock -ModuleName "PSCarbonBlackCloud"  -CommandName "Read-Host" -MockWith {
                        return "3"
                    };

                    { Connect-CBCServer -Menu } | Should -Throw "There is no default server with that index"
                    $CBC_CURRENT_CONNECTIONS | Should -Be $null
                    $CBC_CURRENT_CONNECTIONS.Count | Should -Be 0
                }

                It "Throws an error - on '0' as input" {
                    Mock -ModuleName "PSCarbonBlackCloud"  -CommandName "Read-Host" -MockWith {
                        return "0"
                    };

                    { Connect-CBCServer -Menu } | Should -Throw "There is no default server with that index"
                    $CBC_CURRENT_CONNECTIONS | Should -Be $null
                    $CBC_CURRENT_CONNECTIONS.Count | Should -Be 0
                }

                It "Throws an error - on {letter} as input" {
                    Mock -ModuleName "PSCarbonBlackCloud"  -CommandName "Read-Host" -MockWith {
                        return "ABC"
                    };

                    { Connect-CBCServer -Menu } | Should -Throw "There is no default server with that index"
                    $CBC_CURRENT_CONNECTIONS | Should -Be $null
                    $CBC_CURRENT_CONNECTIONS.Count | Should -Be 0
                }
    
            }

        }

    }
    Context "When in Default section" {

        BeforeDiscovery {
            Disconnect-CBCServer *
        }

        Context "When all args are supplied" {
            BeforeAll {
                $Server = "https://defense-dev01.cbdtest.io/"
                $Org = "ABC"
                $Token = "CDE"
                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                } -ParameterFilter { $Uri -eq $Server }
            }
            
            It "Should return a Server Object" {
                $ServerObject = Connect-CBCServer -Server $Server -Token $Token -Org $Org
                $ServerObject.Server | Should -be "https://defense-dev01.cbdtest.io/"
                $ServerObject.Org | Should -be "ABC"
                $ServerObject.Token | Should -be "CDE"
            }
        }

        Context "When only -Server is supplied" {
            BeforeAll {
                Disconnect-CBCServer *
                $Server = "https://defense-dev01.cbdtest.io/"
                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                } -ParameterFilter { $Uri -eq $Server }
            }

            It "Should return a Server Object" {
                Mock -ModuleName "PSCarbonBlackCloud"  -CommandName "Read-Host" -MockWith {
                    return "ABC"
                }-ParameterFilter { $Prompt -match "Org" }
                Mock -ModuleName "PSCarbonBlackCloud"  -CommandName "Read-Host" -MockWith {
                    return "CDE"
                }-ParameterFilter { $Prompt -match "Token" }

                $ServerObject = Connect-CBCServer -Server $Server
                $ServerObject.Server | Should -be "https://defense-dev01.cbdtest.io/"
                $ServerObject.Org | Should -be "ABC"
                $ServerObject.Token | Should -be "CDE"
            }
        }

        Context "When a invalid -Server is supplied" {
            BeforeAll {
                Disconnect-CBCServer *
                $Server = "NotValidServer"
                $Org = "ABC"
                $Token = "CDE"
                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 404
                    }
                } -ParameterFilter { $Uri -eq $Server }
            }

            It "Should throw an error" {
                { Connect-CBCServer -Server $Server -Org $Org -Token $Token } | Should -Throw "Cannot connect to: NotValidServer"
            }
        }

        Context "When trying to connect to the same server object" {

            BeforeAll {
                $Server = "https://defense-dev01.cbdtest.io/"
                $Org = "ABC"
                $Token = "CDE"

                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                } -ParameterFilter { $Uri -eq $Server }        
                Connect-CBCServer -Server $Server -Token $Token -Org $Org
            }

            It "Should throw an error" {
                { Connect-CBCServer -Server $Server -Org $Org -Token $Token } | Should -Throw "You are already connected to that server!"
            }
        }

        Context "When -SaveCredentials flag is supplied" {

            BeforeAll {
                Disconnect-CBCServer *

                $Server = "https://defense-dev01.cbdtest.io/"
                $Org = "ABC"
                $Token = "CDE"
        
                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                } -ParameterFilter { $Uri -eq $Server }

                Connect-CBCServer -Server $Server -Token $Token -Org $Org -SaveCredentials
            }

            AfterAll 

            BeforeEach {
                $CBC_CREDENTIALS_FULL_PATH = New-Item ./tmp.tests.json
            }

            AfterEach {
                Remove-Item ./tmp.tests.json
            }

            It "Should save the credential is the Credential file" {
                $CheckUri = Select-String -Path $CBC_CREDENTIALS_FULL_PATH -Pattern "${Server}"
                $CheckUri | Should -Not -BeNullOrEmpty
            }
            
            It "Should throw an error" {
                Connect-CBCServer -Server $Server -Token $Token -Org $Org -SaveCredentials
                
            }

        }

        Context "When a connection is active" {

            BeforeAll {
                Disconnect-CBCServer *
            }

            BeforeEach {
                $Server = "https://defense-dev01.cbdtest.io/"
                $Org = "ABC"
                $Token = "CDE"

                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                } -ParameterFilter { $Uri -eq $Server }

                Connect-CBCServer -Server $Server -Token $Token -Org $Org
            }

            AfterEach {
                Disconnect-CBCServer *
            }

            It "Should have multiple current connections" {
                $Server1 = "https://defense-dev02.cbdtest.io/"
                $Org1 = "ABCD"
                $Token1 = "CEF"

                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                } -ParameterFilter { $Uri -eq $Server1 }

                # Skipping the Warning for multiple connections
                Mock -ModuleName PSCarbonBlackCloud -CommandName "Read-Host" -MockWith{
                    return "1"
                }
                Connect-CBCServer -Server $Server1 -Token $Token1 -Org $Org1
                $CBC_CURRENT_CONNECTIONS.Count | Should -be 2
            }

            It "Should exit based on warning" {
                $Server1 = "https://defense-dev02.cbdtest.io/"
                $Org1 = "ABCD"
                $Token1 = "CEF"

                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                } -ParameterFilter { $Uri -eq $Server1 }

                # Skipping the Warning for multiple connections
                Mock -ModuleName PSCarbonBlackCloud -CommandName "Read-Host" -MockWith{
                    return "q"
                }
                { Connect-CBCServer -Server $Server1 -Token $Token1 -Org $Org1 } | Should -Throw "Exit"
                $CBC_CURRENT_CONNECTIONS.Count | Should -be 1
            }
        }

    }

}