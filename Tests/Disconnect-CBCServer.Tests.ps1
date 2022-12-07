Describe "Disconnect-CBCServer" {

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
            Uri        = "https://test03.adasdagf/"
            Org        = "tes331t"
            Token      = "test"
        }
    }

    BeforeEach {
        $CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
    }

    AfterAll {
        $CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
    }

    It "Disconnects all connection" {
        $CBC_CONFIG.currentConnections.Add($TestServerObject1)
        $CBC_CONFIG.currentConnections.Add($TestServerObject2)

        Disconnect-CBCServer *

        $CBC_CONFIG.currentConnections.Count | Should -Be 0
    }

    It "Disconnects an object connection" {
        $CBC_CONFIG.currentConnections.Add($TestServerObject1)
        $CBC_CONFIG.currentConnections.Add($TestServerObject2)

        Disconnect-CBCServer $TestServerObject1

        $CBC_CONFIG.currentConnections.Count | Should -Be 1
        $CBC_CONFIG.currentConnections[0].Uri | Should -Be $TestServerObject2.Uri
    }

    It "Disconnects multiple objects connections" {
        $CBC_CONFIG.currentConnections.Add($TestServerObject1)
        $CBC_CONFIG.currentConnections.Add($TestServerObject2)

        Disconnect-CBCServer @($TestServerObject1, $TestServerObject2)

        $CBC_CONFIG.currentConnections.Count | Should -Be 0
    }

    It "Disconnects a string connection" {
        $CBC_CONFIG.currentConnections.Add($TestServerObject1)
        $CBC_CONFIG.currentConnections.Add($TestServerObject2)

        Disconnect-CBCServer $TestServerObject1.Uri
        $CBC_CONFIG.currentConnections.Count | Should -Be 1
        $CBC_CONFIG.currentConnections[0].Uri | Should -Be $TestServerObject2.Uri
    }

    It "Disconnects multiple string connections" {
        $CBC_CONFIG.currentConnections.Add($TestServerObject1)
        $CBC_CONFIG.currentConnections.Add($TestServerObject2)
        $CBC_CONFIG.currentConnections.Add($TestServerObject3)

        Disconnect-CBCServer @($TestServerObject1.Uri, $TestServerObject2.Uri)
        $CBC_CONFIG.currentConnections.Count | Should -Be 1
        $CBC_CONFIG.currentConnections[0].Uri | Should -Be $TestServerObject3.Uri
    }

}