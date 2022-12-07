Describe "Connect-CBCServer" {

    BeforeAll {
        $TestServerObject1 = [PSCustomObject]@{
            PSTypeName = "CBCServer"
            Uri        = "https://test.adasdagf/"
            Org        = "test"
            Token      = "test"
        }
        $TestServerObject2 = [PSCustomObject]@{
            PSTypeName = "CBCServer"
            Uri        = "https://test02.adasdagf/"
            Org        = "test"
            Token      = "test"
        }
        $TestServerObject3 = [PSCustomObject]@{
            PSTypeName = "CBCServer"
            Uri        = "https://test.adasdagf/"
            Org        = "tes331t"
            Token      = "test"
        }
    }

    BeforeEach {
        $CBC_CONFIG.defaultServers = [System.Collections.ArrayList]@()
        $CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
    }

    AfterAll {
        $CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
        $CBC_CONFIG.defaultServers = [System.Collections.ArrayList]@()
    }

    Context "When in Menu section" {

        Context "On empty Menu" {

            It "Throws an error" {
                { Connect-CBCServer -Menu } | Should -Throw
            }

        }

        Context "On non-empty Menu" {

            It "Should select the second server" {
                $CBC_CONFIG.defaultServers.Add($TestServerObject1)
                $CBC_CONFIG.defaultServers.Add($TestServerObject2)
                $CBC_CONFIG.defaultServers.Add($TestServerObject3)

                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                } -ParameterFilter { $Uri -eq $TestServerObject2.Uri }

                Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
                    return "2"
                };

                $result = Connect-CBCServer -Menu

                $TestServerObject2.Uri | Should -Be $result.Uri
                $TestServerObject2.Org | Should -Be $result.Org
                $TestServerObject2.Token | Should -Be $result.Token
                $CBC_CONFIG.currentConnections.Count | Should -Be 1
            }

            It "Should throw an error" {
                $CBC_CONFIG.defaultServers.Add($TestServerObject1)
                $CBC_CONFIG.defaultServers.Add($TestServerObject2)

                Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
                    return "test"
                };

                { Connect-CBCServer -Menu } | Should -Throw
            }

        }

    }

    Context "When in Default section" {

        It "Should return a CBC Server Object on all Args" {
            Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                return @{
                    StatusCode = 200
                }
            } -ParameterFilter { $Uri -eq $TestServerObject1.Uri }
            $ServerObject = Connect-CBCServer -Uri $TestServerObject1.Uri -Token $TestServerObject1.Token -Org $TestServerObject1.Org
            
            $TestServerObject1.Uri | Should -be $ServerObject.Uri
            $TestServerObject1.Org | Should -be $ServerObject.Org
            $TestServerObject1.Token | Should -be $ServerObject.Token
            $CBC_CONFIG.currentConnections.Count | Should -Be 1
            $CBC_CONFIG.currentConnections[0].Uri | Should -Be $TestServerObject1.Uri
            $CBC_CONFIG.currentConnections[0].Org | Should -Be $TestServerObject1.Org
            $CBC_CONFIG.currentConnections[0].Token | Should -Be $TestServerObject1.Token
        }

        It "Should throw an error when invalid server" {
            $Server404Uri = "http://asd.asd/"
            Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                return @{
                    StatusCode = 404
                }
            } -ParameterFilter { $Uri -eq $Server404Uri }
            { Connect-CBCServer -Uri $Server404Uri -Org "test" -Token "test" } | Should -Throw
            $CBC_CONFIG.currentConnections.Count | Should -Be 0
        }

        It "Should throw an error when you are already connected to the same CBC server" {
            $CBC_CONFIG.currentConnections.Add($TestServerObject1)
            Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
                return ""
            };
            { Connect-CBCServer -Uri $TestServerObject1.Uri -Org $TestServerObject1.Org -Token $TestServerObject1.Token } | Should -Throw
            $CBC_CONFIG.currentConnections.Count | Should -Be 1
        }

        It "Should connect to a second CBC server when already connected to another" {
            Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                return @{
                    StatusCode = 200
                }
            } -ParameterFilter { $Uri -eq $TestServerObject2.Uri }

            # Mock the Warning prompt
            Mock -ModuleName PSCarbonBlackCloud -CommandName "Read-Host" -MockWith {
                return "2"
            }

            $CBC_CONFIG.currentConnections.Add($TestServerObject1)

            $ServerObject = Connect-CBCServer -Uri $TestServerObject2.Uri -Token $TestServerObject2.Token -Org $TestServerObject2.Org

            $TestServerObject2.Uri | Should -be $ServerObject.Uri
            $TestServerObject2.Org | Should -be $ServerObject.Org
            $TestServerObject2.Token | Should -be $ServerObject.Token

            $CBC_CONFIG.currentConnections.Count | Should -Be 2
            $CBC_CONFIG.currentConnections[0].Uri | Should -Be $TestServerObject1.Uri
            $CBC_CONFIG.currentConnections[0].Org | Should -Be $TestServerObject1.Org
            $CBC_CONFIG.currentConnections[0].Token | Should -Be $TestServerObject1.Token
            $CBC_CONFIG.currentConnections[1].Uri | Should -Be $TestServerObject2.Uri
            $CBC_CONFIG.currentConnections[1].Org | Should -Be $TestServerObject2.Org
            $CBC_CONFIG.currentConnections[1].Token | Should -Be $TestServerObject2.Token
        }

        Context "When -SaveCredentials flag is supplied" {

            # Mock the `credentialsFullPath`
            BeforeAll {
                $currentFolder = Get-Location
                $path = "${currentFolder}/tmp.xml"
                New-Item -Path $path -ItemType "file"
                Add-Content -Path $path -Value "<CBCServers></CBCServers>"
                $ENV:orgCredentialsFullPath = $CBC_CONFIG.credentialsFullPath
                $CBC_CONFIG.credentialsFullPath = $path
            }

            AfterAll {
                Remove-Item -Path $path
                $CBC_CONFIG.credentialsFullPath = $ENV:orgCredentialsFullPath
                $ENV:orgCredentialsFullPath = $null
            }

            It "Should save the credentials to a file" {
                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                } -ParameterFilter { $Uri -eq $TestServerObject1.Uri }

                Connect-CBCServer -Uri $TestServerObject1.Uri -Token $TestServerObject1.Token -Org $TestServerObject1.Org -SaveCredentials

                $serverObjects = Select-Xml -Path $CBC_CONFIG.credentialsFullPath -XPath '/CBCServers/CBCServer'
                $serverObjects[0].Node.Uri | Should -Be $TestServerObject1.Uri
                $serverObjects[0].Node.Org | Should -Be $TestServerObject1.Org
                $serverObjects[0].Node.Token | Should -Be $TestServerObject1.Token
            }

        }

    }

}