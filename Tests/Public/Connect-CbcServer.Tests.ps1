using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Connect-CbcServer" {
	BeforeEach {
		$global:CBC_CONFIG.defaultServers = [System.Collections.ArrayList]@()
		$global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
	}

	Context "When using the 'default' parameter set - exception" {
		BeforeAll {
			Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 500
				}
			}
		}

		It 'Should not connect to a server successfully' {
			{Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test" -ErrorAction Stop} | Should -Throw
		}
	}

	Context "When using the 'default' parameter set" {
		BeforeAll {
			Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 200
				}
			}
		}

		It 'Should connect to a server successfully' {
			$server = Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test"

			$server.GetType() | Should -Be "CbcServer"
			$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be $server.Uri
			$global:CBC_CONFIG.currentConnections[0].Org | Should -Be $server.Org
			$global:CBC_CONFIG.defaultServers.Count | Should -Be 0
		}

		It 'Should connect to a server successfully and save the credentials' {
			$server = Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test" -SaveCredential

			$server.GetType() | Should -Be "CbcServer"
			$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be $server.Uri
			$global:CBC_CONFIG.currentConnections[0].Org | Should -Be $server.Org
			$global:CBC_CONFIG.defaultServers.Count | Should -Be 1

			$global:CBC_CONFIG.credentials.RemoveFromFile($server)
		}

		It 'Should connect to a second server successfully' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				""
			}

			$server = Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test"
			$server2 = Connect-CbcServer -Server "https://t2.te/" -Org "test2" -Token "test2"

			$global:CBC_CONFIG.currentConnections.Count | Should -Be 2
			$global:CBC_CONFIG.currentConnections[1].Uri | Should -Be $server2.Uri
			$global:CBC_CONFIG.currentConnections[1].Org | Should -Be $server2.Org
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be $server.Uri
			$global:CBC_CONFIG.currentConnections[0].Org | Should -Be $server.Org
			$global:CBC_CONFIG.defaultServers.Count | Should -Be 0
		}

		It 'Should not connect to a second server if you try to connect to the same server' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				""
			}

			$server = Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test"
			{ Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test" } | Should -Throw

			$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be $server.Uri
			$global:CBC_CONFIG.currentConnections[0].Org | Should -Be $server.Org
			$global:CBC_CONFIG.defaultServers.Count | Should -Be 0
		}

		It 'Should exit (on the warning) when connecting to a second server' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				 "Q"
			}

			$server = Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test"
			{ Connect-CbcServer -Server "https://t2.te/" -Org "test2" -Token "test2" } | Should -Throw

			$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be $server.Uri
			$global:CBC_CONFIG.currentConnections[0].Org | Should -Be $server.Org
			$global:CBC_CONFIG.defaultServers.Count | Should -Be 0
		}
	}

	Context "When using the 'menu' parameter set" {
		BeforeAll {
			Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 200
				}
			}
		}

		It 'Should choose a server and connect to it successfully' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				"1"
			}

			$global:CBC_CONFIG.defaultServers.Add([CbcServer]::new("https://t.te/","test","test"))

			Connect-CbcServer -Menu

			$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be "https://t.te/"
		}

		It 'Should choose the second server and connect to it successfully' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				"2"
			}

			$global:CBC_CONFIG.defaultServers.Add([CbcServer]::new("https://t.te/","test","test"))
			$global:CBC_CONFIG.defaultServers.Add([CbcServer]::new("https://t2.te/","test2","test2"))

			Connect-CbcServer -Menu

			$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be "https://t2.te/"
		}

		It 'Should not choose any server and throw error' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				"q"
			}

			$global:CBC_CONFIG.defaultServers.Add([CbcServer]::new("https://t.te/","test","test"))

			{ Connect-CbcServer -Menu } | Should -Throw

			$global:CBC_CONFIG.currentConnections.Count | Should -Be 0
		}

		It 'Should throw error as no default servers' {
			{ Connect-CbcServer -Menu -ErrorAction Stop } | Should -Throw
		}
	}
}
