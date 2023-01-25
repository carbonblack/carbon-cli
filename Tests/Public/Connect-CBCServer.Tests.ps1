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

	BeforeAll {
		Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
			return @{
				StatusCode = 200
			}
		}
	}

	BeforeEach {
		$global:CBC_CONFIG.defaultServers = [System.Collections.ArrayList]@()
		$global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
	}

	Context "When using the 'default' parameter set" {
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
				return ""
			};

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
				return ""
			};

			$server = Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test"
			{ Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test" } | Should -Throw

			$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be $server.Uri
			$global:CBC_CONFIG.currentConnections[0].Org | Should -Be $server.Org
			$global:CBC_CONFIG.defaultServers.Count | Should -Be 0
		}
		It 'Should exit (on the warning) when connecting to a second server' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				return "Q"
			};

			$server = Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test"
			{ Connect-CbcServer -Server "https://t2.te/" -Org "test2" -Token "test2" } | Should -Throw

			$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be $server.Uri
			$global:CBC_CONFIG.currentConnections[0].Org | Should -Be $server.Org
			$global:CBC_CONFIG.defaultServers.Count | Should -Be 0
		}
	}

	Context "When using the 'menu' parameter set" {
		It 'Should choose a server and connect to it successfully' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				return "1"
			};

			$global:CBC_CONFIG.defaultServers.Add([CbcServer]::new("https://t.te/","test","test"))

			Connect-CbcServer -Menu

			$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be "https://t.te/"
		}
		It 'Should choose the second server and connect to it successfully' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				return "2"
			};

			$global:CBC_CONFIG.defaultServers.Add([CbcServer]::new("https://t.te/","test","test"))
			$global:CBC_CONFIG.defaultServers.Add([CbcServer]::new("https://t2.te/","test2","test2"))

			Connect-CbcServer -Menu

			$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be "https://t2.te/"
		}
		It 'Should not choose any server and throw error' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				return "q"
			};

			$global:CBC_CONFIG.defaultServers.Add([CbcServer]::new("https://t.te/","test","test"))

			{ Connect-CbcServer -Menu } | Should -Throw

			$global:CBC_CONFIG.currentConnections.Count | Should -Be 0
		}
	}
}
