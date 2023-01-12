using module ..\..\src\PSCarbonBlackCloud.Classes.psm1



BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}


Describe "Get-CBCDevice" {

    Context "When using multiple connections with a specific server" {

        BeforeAll {
            $s1 = [CBCServer]::new("https://t.te/","test","test")
            $s2 = [CBCServer]::new("https://t.te2/","test2","test2")
            $global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
            $global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
            $global:CBC_CONFIG.currentConnections.Add($s2) | Out-Null
        }

        It "Should return devices only from the specific server" {
            Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                    return @{
                        StatusCode = 200
                        Content = Get-Content "$ProjectRoot/Tests/resources/device_api/all_devices.json"
                    }
                }

                $devices = Get-CBCDevice -Server @($s1)

                $devices.Count | Should -Be 3
                $devices[0].User | Should -Be "test1@carbonblack.com"
                $devices[0].CBCServer | Should -Be $s1
                $devices[1].User | Should -Be "test2@carbonblack.com"
                $devices[2].User | Should -Be "test3@carbonblack.com"
                $devices[0].Id | Should -Be 1
                $devices[1].Id | Should -Be 2
                $devices[2].Id | Should -Be 3
        }
    }
    Context "When using the 'default' parameter set" {
        Context "When using one connection" {

            BeforeAll {
                $s1 = [CBCServer]::new("https://t.te/","test","test")
                $global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
                $global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
            }

            Context "When not using any params" {
                It "Should return all the devices within the current connection" {
                    Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                        return @{
                            StatusCode = 200
                            Content = Get-Content "$ProjectRoot/Tests/resources/device_api/all_devices.json"
                        }
                    }

                    $devices = Get-CBCDevice
                    $devices.Count | Should -Be 3
                    $devices[0].User | Should -Be "test1@carbonblack.com"
                    $devices[0].CBCServer | Should -Be $s1
                    $devices[1].User | Should -Be "test2@carbonblack.com"
                    $devices[2].User | Should -Be "test3@carbonblack.com"
                    $devices[0].Id | Should -Be 1
                    $devices[1].Id | Should -Be 2
                    $devices[2].Id | Should -Be 3
                }
            }

            Context "When using the -Exclude parameter" {
                It "Should return the devices according to the exclusion" {
                    $ExampleJSONBody = '{"exclusions": { "sensor_version": ["windows:1.0.0"] }, "rows": 50 }' | ConvertFrom-Json | ConvertTo-Json

                    Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                        return @{
                            StatusCode = 200
                            Content = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
                        }
                    } -ParameterFilter {
                        $Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
                        $Method -eq "POST" -and
                        $Server -eq $s1 -and
                        $Body -eq $ExampleJSONBody
                    }
                    $Exclusions = @{
                        "sensor_version" = @("windows:1.0.0")
                    }

                    $devices = Get-CBCDevice -Exclude $Exclusions

                    $devices.Count | Should -Be 1
                    $devices[0].CBCServer | Should -Be  $s1
                    $devices[0].User | Should -Be "test3@carbonblack.com"
                    $devices[0].Os | Should -Be "LINUX"
                }
            }
            Context "When using the -Include parameter" {
                It "Should return the devices according to the inclusion" {
                    $ExampleJSONBody = '{"rows": 50, "criteria": { "os": ["WINDOWS"] }}' | ConvertFrom-Json | ConvertTo-Json
                    Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                        return @{
                            StatusCode = 200
                            Content = Get-Content "$ProjectRoot/Tests/resources/device_api/criteria_devices.json"
                        }
                    } -ParameterFilter {
                        $Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
                        $Method -eq "POST" -and
                        ($Server -eq $s1 -or $Server -eq $s2) -and
                        $Body -eq $ExampleJSONBody
                    }
                    $Criteria = @{
                        "os" = @("WINDOWS")
                    }

                    $devices = Get-CBCDevice -Include $Criteria

                    $devices.Count | Should -Be 2
                    $devices[0].CBCServer | Should -Be $s1
                    $devices[1].CBCServer | Should -Be $s1
                    $devices[0].User | Should -Be "test1@carbonblack.com"
                    $devices[1].User | Should -Be "test2@carbonblack.com"
                    $devices[0].Os | Should -Be "WINDOWS"
                    $devices[1].Os | Should -Be "WINDOWS"
                }
            }
            Context "When using the -Include -Exclude and -MaxResults params" {
                It "Should return the devices according to the inclusion and exclusion" {
                    # This test is for testing only if the `$Body` of the `Invoke-CBCRequests`
                    # actually receives the `exclusions` part of the request. The other stuff
                    # are already tested and redundant. The test would be useful for future
                    # supported fileds, more than just the `sensor_version`.
                    $ExampleJSONBody = '{"exclusions": { "sensor_version": ["windows:1.0.0"]},"rows": 20, "criteria": { "os": ["WINDOWS"] }}' | ConvertFrom-Json | ConvertTo-Json
                    Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                        return @{
                            StatusCode = 200
                            Content = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_criteria_devices.json"
                        }
                    } -ParameterFilter {
                        $Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
                        $Method -eq "POST" -and
                        $Server -eq $s1 -and
                        $Body -eq $ExampleJSONBody
                    }
                    $Criteria = @{
                        "os" = @("WINDOWS")
                    }
                    $Exclusions = @{
                        "sensor_version" = @("windows:1.0.0")
                    }

                    $devices = Get-CBCDevice -Exclude $Exclusions -Include $Criteria -MaxResults 20

                    $devices.Count | Should -Be 3
                    $devices[0].User | Should -Be "test1@carbonblack.com"
                    $devices[1].User | Should -Be "test2@carbonblack.com"
                    $devices[2].User | Should -Be "test3@carbonblack.com"
                    $devices[0].Id | Should -Be 1
                    $devices[1].Id | Should -Be 2
                    $devices[2].Id | Should -Be 3
                }
            }
        }
        Context "When using multiple connection" {

            BeforeAll {
                $s1 = [CBCServer]::new("https://t.te/","test","test")
                $s2 = [CBCServer]::new("https://t.te2/","test2","test2")
                $global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
                $global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
                $global:CBC_CONFIG.currentConnections.Add($s2) | Out-Null
            }

            Context "When not using any params" {
                It "Should return all the devices from multiple servers" {

                    Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                        return @{
                            StatusCode = 200
                            Content = Get-Content "$ProjectRoot/Tests/resources/device_api/all_devices.json"
                        }
                    }

                    $devices = Get-CBCDevice

                    $devices.Count | Should -Be 6
                    $devices[0].User | Should -Be "test1@carbonblack.com"
                    $devices[2].User | Should -Be "test3@carbonblack.com"
                    $devices[0].Id | Should -Be 1
                    $devices[2].Id | Should -Be 3
                    $devices[0].CBCServer | Should -Be $s1
                    $devices[2].CBCServer | Should -Be $s1
                    $devices[3].User | Should -Be "test1@carbonblack.com"
                    $devices[5].User | Should -Be "test3@carbonblack.com"
                    $devices[3].Id | Should -Be 1
                    $devices[5].Id | Should -Be 3
                    $devices[3].CBCServer | Should -Be $s2
                    $devices[5].CBCServer | Should -Be $s2
                }
            }
            Context "When using the -Exclude parameter" {
                It "Should return the devices according to the exclusion from multiple servers" {
                    $ExampleJSONBody = '{"exclusions": { "os": ["WINDOWS"] } }' | ConvertFrom-Json | ConvertTo-Json
                    Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                        return @{
                            StatusCode = 200
                            Content = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_devices.json"
                        }
                    } -ParameterFilter {
                        $Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"]
                        $Method -eq "POST"
                        $Server -eq $s1
                        $Body -eq $ExampleJSONBody
                    }
                    $Exclusions = @{
                        "os" = "WINDOWS"
                    }

                    $devices = Get-CBCDevice -Exclude $Exclusions

                    $devices.Count | Should -Be 2
                    $devices[0].CBCServer | Should -Be $s1
                    $devices[0].User | Should -Be "test3@carbonblack.com"
                    $devices[0].Os | Should -Be "LINUX"
                    $devices[1].CBCServer | Should -Be $s2
                    $devices[1].User | Should -Be "test3@carbonblack.com"
                    $devices[1].Os | Should -Be "LINUX"
                }
            }
            Context "When using the -Include parameter" {
                It "Should return the devices according to the inclusion from multiple servers" {
                    $ExampleJSONBody = '{"criteria": { "os": ["WINDOWS"] } }' | ConvertFrom-Json | ConvertTo-Json
                    Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                        return @{
                            StatusCode = 200
                            Content = Get-Content "$ProjectRoot/Tests/resources/device_api/criteria_devices.json"
                        }
                    } -ParameterFilter {
                        $Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"]
                        $Method -eq "POST"
                        $Server -eq $s1
                        $Body -eq $ExampleJSONBody
                    }
                    $Criteria = @{
                        "os" = @("WINDOWS")
                    }

                    $devices = Get-CBCDevice -Include $Criteria

                    $devices.Count | Should -Be 4
                    $devices[0].CBCServer | Should -Be $s1
                    $devices[1].CBCServer | Should -Be $s1
                    $devices[0].User | Should -Be "test1@carbonblack.com"
                    $devices[1].User | Should -Be "test2@carbonblack.com"
                    $devices[0].Os | Should -Be "WINDOWS"
                    $devices[1].Os | Should -Be "WINDOWS"

                    $devices[2].CBCServer | Should -Be $s2
                    $devices[3].CBCServer | Should -Be $s2
                    $devices[2].User | Should -Be "test1@carbonblack.com"
                    $devices[3].User | Should -Be "test2@carbonblack.com"
                    $devices[2].Os | Should -Be "WINDOWS"
                    $devices[3].Os | Should -Be "WINDOWS"
                }
            }
            Context "When using the -Include and -Exclude params" {
                It "Should return the devices according to the inclusion and exclusion from multiple servers" {
                    # This test is for testing only if the `$Body` of the `Invoke-CBCRequests`
                    # actually receives the `exclusions` part of the request. The other stuff
                    # are already tested and redundant. The test would be useful for future
                    # supported fileds, more than just the `sensor_version`.
                    $ExampleJSONBody = '{"criteria": { "os": ["WINDOWS"] }, "exclusions": { "sensor_version": ["windows:1.0.0"]} }' | ConvertFrom-Json | ConvertTo-Json
                    Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                        return @{
                            StatusCode = 200
                            Content = Get-Content "$ProjectRoot/Tests/resources/device_api/exclusions_criteria_devices.json"
                        }
                    } -ParameterFilter {
                        $Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"]
                        $Method -eq "POST"
                        $Server -eq $s1
                        $Body -eq $ExampleJSONBody
                    }
                    $Criteria = @{
                        "os" = @("WINDOWS")
                    }
                    $Exclusions = @{
                        "sensor_version" = "windows:1.0.0"
                    }

                    $devices = Get-CBCDevice -Exclude $Exclusions -Include $Criteria

                    $devices = Get-CBCDevice
                    $devices.Count | Should -Be 6
                    $devices[0].CBCServer | Should -Be $s1
                    $devices[5].CBCServer | Should -Be $s2
                    $devices[0].User | Should -Be "test1@carbonblack.com"
                    $devices[1].User | Should -Be "test2@carbonblack.com"
                    $devices[2].User | Should -Be "test3@carbonblack.com"
                    $devices[0].Id | Should -Be 1
                    $devices[1].Id | Should -Be 2
                    $devices[2].Id | Should -Be 3
                    $devices[3].User | Should -Be "test1@carbonblack.com"
                    $devices[4].User | Should -Be "test2@carbonblack.com"
                    $devices[5].User | Should -Be "test3@carbonblack.com"
                    $devices[3].Id | Should -Be 1
                    $devices[4].Id | Should -Be 2
                    $devices[5].Id | Should -Be 3
                }
            }
        }
    }
    Context "When using the 'query' parameter set" {
        Context "When using one connection" {

            BeforeAll {
                $s1 = [CBCServer]::new("https://t.te/","test","test")
                $global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
                $global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
            }

            It "Should return devices based on the query" {
                $ExampleJSONBody = '{"query": "os:Windows", "rows": 50 }' | ConvertFrom-Json | ConvertTo-Json
                Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                    return @{
                        StatusCode = 200
                        Content = Get-Content "$ProjectRoot/Tests/resources/device_api/criteria_devices.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Devices"]["Search"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1 -and
                    $Body -eq $ExampleJSONBody
                }

                $devices = Get-CBCDevice -Filter "os:Windows"

                $devices.Count | Should -Be 2
                $devices[0].CBCServer | Should -Be $s1
                $devices[1].CBCServer | Should -Be $s1
                $devices[0].User | Should -Be "test1@carbonblack.com"
                $devices[1].User | Should -Be "test2@carbonblack.com"
                $devices[1].Os | Should -Be "WINDOWS"
                $devices[0].Os | Should -Be "WINDOWS"
                $devices[0].Id | Should -Be 1
                $devices[1].Id | Should -Be 2
            }
        }
        Context "When using multiple connection" {

            BeforeAll {
                $s1 = [CBCServer]::new("https://t.te/","test","test")
                $s2 = [CBCServer]::new("https://t.te2/","test2","test2")
                $global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
                $global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
                $global:CBC_CONFIG.currentConnections.Add($s2) | Out-Null
            }

            It "Should return devices based on the query from multiple servers" {
                Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                    return @{
                        StatusCode = 200
                        Content = Get-Content "$ProjectRoot/Tests/resources/device_api/criteria_devices.json"
                    }
                }

                $devices = Get-CBCDevice -Filter "os:Windows"

                $devices.Count | Should -Be 4
                $devices[0].CBCServer | Should -Be $s1
                $devices[2].CBCServer | Should -Be $s2
                $devices[0].User | Should -Be "test1@carbonblack.com"
                $devices[3].User | Should -Be "test2@carbonblack.com"
                $devices[0].Os | Should -Be "WINDOWS"
                $devices[2].Os | Should -Be "WINDOWS"
                $devices[0].Id | Should -Be 1
                $devices[2].Id | Should -Be 1
            }
        }
    }
    Context "When using the 'id' parameter set" {
        Context "When using one connection" {

            BeforeAll {
                $s1 = [CBCServer]::new("https://t.te/","test","test")
                $global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
                $global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
            }

            It "Should return device with the same id" {
                Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                    return @{
                        StatusCode = 200
                        Content = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
                    }
                }

                $devices = Get-CBCDevice -Id "5765373"

                $devices.Count | Should -Be 1
                $devices[0].Id | Should -Be "5765373"
                $devices[0].User | Should -Be "vagrant"
            }

            It "Should return device with the same id without '-Id' param" {
                Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                    return @{
                        StatusCode = 200
                        Content = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
                    }
                }

                $devices = Get-CBCDevice "5765373"

                $devices.Count | Should -Be 1
                $devices[0].Id | Should -Be "5765373"
                $devices[0].User | Should -Be "vagrant"
            }
        }
        Context "When using multiple connection" {

            BeforeAll {
                $s1 = [CBCServer]::new("https://t.te/","test","test")
                $s2 = [CBCServer]::new("https://t.te2/","test2","test2")
                $global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
                $global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
                $global:CBC_CONFIG.currentConnections.Add($s2) | Out-Null
            }

            It "Should return devices with the same id from multiple servers" {

                Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                    return @{
                        StatusCode = 200
                        Content = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
                    }
                }

                $devices = Get-CBCDevice -Id "5765373"

                $devices.Count | Should -Be 2
                $devices[0].Id | Should -Be "5765373"
                $devices[0].User | Should -Be "vagrant"
            }

            It "Should return devices with the same id without '-Id' param from multiple servers" {
                Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
                    return @{
                        StatusCode = 200
                        Content = Get-Content "$ProjectRoot/Tests/resources/device_api/specific_device.json"
                    }
                }

                $devices = Get-CBCDevice "5765373"

                $devices.Count | Should -Be 2
                $devices[0].Id | Should -Be "5765373"
                $devices[0].User | Should -Be "vagrant"
            }
        }
    }

}
