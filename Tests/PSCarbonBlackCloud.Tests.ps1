Import-Module /Users/gmirela/PSCarbonBlackCloud/PSCarbonBlackCloud/PSCarbonBlackCloud.psm1
Describe "Connect-CBCServer" {
    It "Should return a Server Object" {
        $Server = "https://defense-dev01.cbdtest.io/"
        $Org = "ABC"
        $Token = "CDE"
        
        Disconnect-CBCServer *
        
        Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
            return @{
                StatusCode = 200
            }
        } -ParameterFilter { $Uri -eq $Server }
        $ServerObject = Connect-CBCServer -Server $Server -Token $Token -Org $Org
        $ServerObject.Server | Should -be "https://defense-dev01.cbdtest.io/"
        $ServerObject.Org | Should -be "ABC"
        $ServerObject.Token | Should -be "CDE"
    }

    It "Should return error for not a valid server" {
        $Server = "NotValidServer"
        $Org = "ABC"
        $Token = "CDE"
        Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
            return @{
                StatusCode = 404
            }
        } -ParameterFilter { $Uri -eq $Server }

        { Connect-CBCServer -Server $Server -Org $Org -Token $Token } | Should -Throw "Cannot connect to: NotValidServer"
    }

    It "Should return error for trying to connect with already connected server" {
        $Server = "https://defense-dev01.cbdtest.io/"
        $Org = "ABC"
        $Token = "CDE"

        Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
            return @{
                StatusCode = 200
            }
        } -ParameterFilter { $Uri -eq $Server }

        Disconnect-CBCServer *
        
        Connect-CBCServer -Server $Server -Token $Token -Org $Org

        { Connect-CBCServer -Server $Server -Org $Org -Token $Token } | Should -Throw "You are already connected to that server!"
    }

    It "Should save the credentials when -SaveCredentials flag is used" {
        $Server = "https://defense-dev01.cbdtest.io/"
        $Org = "ABC"
        $Token = "CDE"

        Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
            return @{
                StatusCode = 200
            }
        } -ParameterFilter { $Uri -eq $Server }

        Disconnect-CBCServer *
        
        Connect-CBCServer -Server $Server -Token $Token -Org $Org -SaveCredentials
        $CheckUri = Select-String -Path ~/.carbonblack/PSCredentials.json -Pattern "${Server}"

        $CheckUri | Should -Not -BeNullOrEmpty   
    }

    It "Should list the credentials and connect with one" {
        Disconnect-CBCServer *

        $MockServerObject = @{
            Server = "https://defense-dev01.cbdtest.io/"
            Org = "ABC"
            Token = "CDE"
        }
        # Mock -CommandName Read-Host -ParameterFilter { $Prompt -match 'option' } { "1" }
        Mock -CommandName Read-Host { return 1 }
        
        $emptyArray = [System.Collections.ArrayList]@()
        Set-Variable CBC_DEFAULT_SERVERS -Value $emptyArray -Scope Global
        $CBC_DEFAULT_SERVERS.Add($MockServerObject) | Out-Null

        $ServerObject = Connect-CBCServer -Menu

        $ServerObject | Should -be $MockServerObject
    }

    It "Should return error for trying to connect with no such index in Menu"{
        Disconnect-CBCServer *
        Mock -CommandName "Read-Host" `
        -MockWith    {
            return "3000"
        }
        #Mock -CommandName Read-Host -ParameterFilter { $Prompt -match 'option' } { 3000 }
        {Connect-CBCServer -Menu} | Should -Throw "There is no default server with that index"
    }
}

InModuleScope PSCarbonBlackCloud {
    Describe "Test-CBCConnection" {
        It "Should return true" {
            $ServerObject = [PSCustomObject]@{
                Server = "https://carbonblackcloud.io/"
                Org    = "ABC"
                Token  = "CDF"
            }
                
            Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                return @{
                    StatusCode = 200
                }
            } -ParameterFilter { $Uri -eq $ServerObject.Server }
    
            Test-CBCConnection $ServerObject | Should -be $true
        }

        It "Should return false"{
            $ServerObject = [PSCustomObject]@{
                Server = "https://defense-dev.io/"
                Org    = "ABC"
                Token  = "ABC"
            }

            Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                return @{
                    StatusCode = 404
                }
            } -ParameterFilter { $Uri -eq $ServerObject.Server }
    
            Test-CBCConnection $ServerObject | Should -be $false
        }
    }
}

Describe "Disconnect-CBCServer"{
    It "Should unset global variable when supplied a PSCustomObject"{
        $ServerObject = [PSCustomObject]@{
            Server = "https://defense-dev.io/"
            Org    = "ABC"
            Token  = "ABC"
        }
        $emptyArray = [System.Collections.ArrayList]@()
        Set-Variable CBC_CURRENT_CONNECTIONS -Value $emptyArray -Scope Global

        $CBC_CURRENT_CONNECTIONS.Add($ServerObject) | Out-Null
        
        Disconnect-CBCServer $ServerObject
        
        $CBC_CURRENT_CONNECTIONS | Should -be $null
    }
    It "Should unset global variable when supplied a wildcard"{
        $ServerObject = [PSCustomObject]@{
            Server = "https://defense-dev.io/"
            Org    = "ABC"
            Token  = "ABC"
        }
        $ServerObject2 = [PSCustomObject]@{
            Server = "https://defense-dev02.io/"
            Org    = "ABCD"
            Token  = "HFG"
        }
        $emptyArray = [System.Collections.ArrayList]@()
        Set-Variable CBC_CURRENT_CONNECTIONS -Value $emptyArray -Scope Global

        $CBC_CURRENT_CONNECTIONS.Add($ServerObject) | Out-Null
        $CBC_CURRENT_CONNECTIONS.Add($ServerObject2) | Out-Null
        
        Disconnect-CBCServer *
        
        $CBC_CURRENT_CONNECTIONS | Should -be $null
    }

    It "Should unset global variable when supplied a string"{
        $ServerObject = [PSCustomObject]@{
            Server = "https://defense-dev.io/"
            Org    = "ABC"
            Token  = "ABC"
        }
        $emptyArray = [System.Collections.ArrayList]@()
        Set-Variable CBC_CURRENT_CONNECTIONS -Value $emptyArray -Scope Global

        $CBC_CURRENT_CONNECTIONS.Add($ServerObject) | Out-Null
    
        Disconnect-CBCServer "https://defense-dev.io/"
        
        $CBC_CURRENT_CONNECTIONS | Should -be $null
    }

    It "Should unset global variable when supplied a array of strings"{
        $ServerObject = [PSCustomObject]@{
            Server = "https://defense-dev.io/"
            Org    = "ABC"
            Token  = "ABC"
        }
        $ServerObject2 = [PSCustomObject]@{
            Server = "https://defense-dev02.io/"
            Org    = "ABCD"
            Token  = "HFG"
        }
        $emptyArray = [System.Collections.ArrayList]@()
        Set-Variable CBC_CURRENT_CONNECTIONS -Value $emptyArray -Scope Global

        $CBC_CURRENT_CONNECTIONS.Add($ServerObject) | Out-Null
        $CBC_CURRENT_CONNECTIONS.Add($ServerObject2) | Out-Null

        $stringArray = @("https://defense-dev.io/","https://defense-dev02.io/")
        
        Disconnect-CBCServer $stringArray
        
        $CBC_CURRENT_CONNECTIONS | Should -be $null
    }

    It "Should remain the same"{
        $ServerObject = [PSCustomObject]@{
            Server = "https://defense-dev.io/"
            Org    = "ABC"
            Token  = "ABC"
        }

        $emptyArray = [System.Collections.ArrayList]@()
        Set-Variable CBC_CURRENT_CONNECTIONS -Value $emptyArray -Scope Global

        $CBC_CURRENT_CONNECTIONS.Add($ServerObject) | Out-Null

        Disconnect-CBCServer "NotValidName"

        $CBC_CURRENT_CONNECTIONS.Count | Should -be 1
    }
}