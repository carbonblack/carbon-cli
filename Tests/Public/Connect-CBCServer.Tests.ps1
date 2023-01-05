using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Connect-CBCServer" {

	BeforeAll {
		$s1 = [CBCServer]::new("https://t.te/","test","test")
		$s2 = [CBCServer]::new("https://t2.te/","test2","test2")
		$s3 = [CBCServer]::new("https://t3.te/","test3","test3")
	}

	BeforeEach {
		$global:CBC_CONFIG.defaultServers = [System.Collections.ArrayList]@()
		$global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
	}

	Context 'When using the `default` parameter set' {
		It 'Should connect to a server successfully' {
			$server = Connect-CBCServer -Server $s1.Uri -Org $s1.Org -Token $s1.Token

			$server.GetType() | Should -Be "CBCServer"
			$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be $server.Uri
			$global:CBC_CONFIG.currentConnections[0].Org | Should -Be $server.Org
			$global:CBC_CONFIG.defaultServers.Count | Should -Be 0
		}
		It 'Should connect to a server successfully and save the credentials' {
			$server = Connect-CBCServer -Server $s1.Uri -Org $s1.Org -Token $s1.Token -SaveCredential

			$server.GetType() | Should -Be "CBCServer"
			$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be $server.Uri
			$global:CBC_CONFIG.currentConnections[0].Org | Should -Be $server.Org
			$global:CBC_CONFIG.defaultServers.Count | Should -Be 1

			# Cleanup
			$global:CBC_CONFIG.credentials.RemoveFromFile($server)
		}
		It 'Should connect to a second server successfully' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
                return ""
            };

			$server = Connect-CBCServer -Server $s1.Uri -Org $s1.Org -Token $s1.Token
			$server2 = Connect-CBCServer -Server $s2.Uri -Org $s2.Org -Token $s2.Token

			$global:CBC_CONFIG.currentConnections.Count | Should -Be 2
			$global:CBC_CONFIG.currentConnections[1].Uri | Should -Be $server2.Uri
			$global:CBC_CONFIG.currentConnections[1].Org | Should -Be $server2.Org
			$global:CBC_CONFIG.defaultServers.Count | Should -Be 0
		}
		It 'Should exit (on the warning) when connecting to a second server' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
                return "Q"
            };

			$server = Connect-CBCServer -Server $s1.Uri -Org $s1.Org -Token $s1.Token

			{ Connect-CBCServer -Server $s2.Uri -Org $s2.Org -Token $s2.Token } | Should -Throw
			$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
			$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be $server.Uri
			$global:CBC_CONFIG.currentConnections[0].Org | Should -Be $server.Org
			$global:CBC_CONFIG.defaultServers.Count | Should -Be 0
		}
	}

	Context 'When using the `menu` parameter set' {
		It 'Should choose a server and connect to it successfully' {
			
		}
	}
}
