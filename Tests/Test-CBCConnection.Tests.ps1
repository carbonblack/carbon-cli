Describe "Test-CBCConnection" {
    InModuleScope PSCarbonBlackCloud {
        Context "When valid Server is supplied" {
            BeforeAll {
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
            }

            It "Should return true" {
                Test-CBCConnection $ServerObject | Should -be $true
            }
        }

        Context "When invalid Server is supplied" {
            BeforeAll {
                $ServerObject = [PSCustomObject]@{
                    Server = "https://carbonblackcloud.io/"
                    Org    = "ABC"
                    Token  = "CDF"
                }
            
                Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 404
                    }
                } -ParameterFilter { $Uri -eq $ServerObject.Server }
            }
            
            It "Should return false" {
                Test-CBCConnection $ServerObject | Should -be $false
            }
        }
    }
}