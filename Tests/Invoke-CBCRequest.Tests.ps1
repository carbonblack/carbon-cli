Try {
    $private = @(Get-ChildItem -Path "$PSScriptRoot\Private" @dotSourceParams)
}
Catch {
    Throw $_
}

ForEach ($file in @($public + $private)) {
    . $file.FullName
}

Describe "Invoke-CBCRequest" {

    BeforeAll {

        $TestServerObject1 = @{
            Uri = "https://test.adasdagf/"
            Org = "test"
            Token = "test"
        }

        $TestServerObject2 = @{
            Uri = "https://test02.adasdagf/"
            Org = "test"
            Token = "test"
        }

        $TestServerObject3 = @{
            Uri = "https://test03.adasdagf/"
            Org = "tes331t"
            Token = "test"
        }
    }

    # Resetting the State of tests
    BeforeEach {
        $CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
    }

    It "Should return status 200" {

        Mock -ModuleName PSCarbonBlackCloud Invoke-WebRequest -MockWith {
            return @{
                StatusCode = 200
            }
        } -ParameterFilter { 
            $Uri -match "https://test.adasdagf/appservices/v6/orgs/test/devices/123" 
            $Method -match "Get" 
            $Params -match @(123)
        }

        $CBC_CONFIG.currentConnections.Add($TestServerObject1)

        Invoke-CBCRequest -Uri $CBC_CONFIG.endpoints["Devices"]["SpecDevInfo"] -Method "Get" -Params @(123)
    }

}