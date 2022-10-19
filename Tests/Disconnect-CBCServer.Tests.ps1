Describe "Disconnect-CBCServer" {
    Context "When Disconnect-CBCServer is called" {
        Context "On passed Server" {
            BeforeAll {
                $ServerObject = [PSCustomObject]@{
                    Server = "https://defense-dev.io/"
                    Org    = "ABC"
                    Token  = "ABC"
                }
                $emptyArray = [System.Collections.ArrayList]@()
                Set-Variable CBC_CURRENT_CONNECTIONS -Value $emptyArray -Scope Global
                $CBC_CURRENT_CONNECTIONS.Add($ServerObject) | Out-Null
            }
            
            It "Removes a connection from CBC_CURRENT_CONNECTIONS" {
                Disconnect-CBCServer $ServerObject
                $CBC_CURRENT_CONNECTIONS | Should -be $null
            }
        }

        Context "On passed wildcard *" {
            BeforeAll {
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
            }

            It "Removes all connections from CBC_CURRENT_CONNECTIONS" {
                Disconnect-CBCServer *
                $CBC_CURRENT_CONNECTIONS | Should -be $null
            }
        }

        Context "On passed string" {
            BeforeAll {
                $ServerObject = [PSCustomObject]@{
                    Server = "https://defense-dev.io/"
                    Org    = "ABC"
                    Token  = "ABC"
                }
                $emptyArray = [System.Collections.ArrayList]@()
                Set-Variable CBC_CURRENT_CONNECTIONS -Value $emptyArray -Scope Global
        
                $CBC_CURRENT_CONNECTIONS.Add($ServerObject) | Out-Null
            }

            It "Removes a connection from CBC_CURRENT_CONNECTIONS" {
                Disconnect-CBCServer "https://defense-dev.io/"
                $CBC_CURRENT_CONNECTIONS | Should -be $null
            }
        }

        Context "On passed array of strings" {
            BeforeAll {
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
            }

            It "Should remove the connections from CBC_CURRENT_CONNECTIONS" {
                $stringArray = @("https://defense-dev.io/", "https://defense-dev02.io/")
                Disconnect-CBCServer $stringArray
                $CBC_CURRENT_CONNECTIONS | Should -be $null
            }
        }

        Context "On passed invalid input" {
            BeforeAll {
                $ServerObject = [PSCustomObject]@{
                    Server = "https://defense-dev.io/"
                    Org    = "ABC"
                    Token  = "ABC"
                }
        
                $emptyArray = [System.Collections.ArrayList]@()
                Set-Variable CBC_CURRENT_CONNECTIONS -Value $emptyArray -Scope Global
        
                $CBC_CURRENT_CONNECTIONS.Add($ServerObject) | Out-Null
        
            }

            It "Should remain the same" {
                Disconnect-CBCServer "NotValidName"
                $CBC_CURRENT_CONNECTIONS.Count | Should -be 1
            }
        }
    }
}