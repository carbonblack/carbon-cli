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
		$global:defaultCbcServers = [System.Collections.ArrayList]@()
		$global:CBC_CONFIG.sessionConnections = [System.Collections.ArrayList]@()
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
			$Uri = "https://t.te/"
			$Org = "test"
			$Token = "test"
			$Notes = " Test server"
			$server = Connect-CbcServer -Server $Uri -Org $Org -Token $Token -Notes $Notes

			$server.GetType() | Should -Be "CbcServer"
			$server.Uri | Should -Be $Uri
			$server.Org | Should -Be $Org
			$server.Notes | Should -Be $Notes

			$global:CBC_CONFIG.sessionConnections.Count | Should -Be 0
			$global:defaultCbcServers.Count | Should -Be 1
			$global:defaultCbcServers.Uri | Should -Be $server.Uri
			$global:defaultCbcServers.Org | Should -Be $server.Org
			$global:defaultCbcServers.Notes | Should -Be $server.Notes
		}

		It 'Should connect to a server successfully and save the connection' {
			$server = Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test" -SaveConnection

			$server.GetType() | Should -Be "CbcServer"
			$global:CBC_CONFIG.sessionConnections.Count | Should -Be 1
			$global:CBC_CONFIG.sessionConnections[0].Uri | Should -Be $server.Uri
			$global:CBC_CONFIG.sessionConnections[0].Org | Should -Be $server.Org
			$global:defaultCbcServers.Count | Should -Be 1
			$global:defaultCbcServers.Uri | Should -Be $server.Uri
			$global:defaultCbcServers.Org | Should -Be $server.Org

			$global:CBC_CONFIG.savedConnections.RemoveFromFile($server)
		}

		It 'Should connect to a second server successfully' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				""
			}

			$server = Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test"
			$server2 = Connect-CbcServer -Server "https://t2.te/" -Org "test2" -Token "test2"

			$global:defaultCbcServers.Count | Should -Be 2
			$global:defaultCbcServers[1].Uri | Should -Be $server2.Uri
			$global:defaultCbcServers[1].Org | Should -Be $server2.Org
			$global:defaultCbcServers[0].Uri | Should -Be $server.Uri
			$global:defaultCbcServers[0].Org | Should -Be $server.Org
			$global:CBC_CONFIG.sessionConnections.Count | Should -Be 0
		}

		It 'Should not connect to a second server if you try to connect to the same server and no -Notes provided' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				""
			}

			$server = Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test"
			{ Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test" } | Should -Throw

			
			$server.GetType() | Should -Be "CbcServer"
			$global:CBC_CONFIG.sessionConnections.Count | Should -Be 0
			$global:defaultCbcServers.Count | Should -Be 1
			$global:defaultCbcServers.Uri | Should -Be $server.Uri
			$global:defaultCbcServers.Org | Should -Be $server.Org
		}

		It 'Should update the notes if you try to connect to the same server and -Notes param provided' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				""
			}

			$server = Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test" -Notes "Test notes "
			$server = Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test" -Notes  "Updated Notes"

			
			$server.Notes | Should -Be "Updated Notes"
			$global:defaultCbcServers.Notes | Should -Be "Updated Notes"
			
		}

		It 'Should exit (on the warning) when connecting to a second server' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				 "Q"
			}

			$server = Connect-CbcServer -Server "https://t.te/" -Org "test" -Token "test"
			{ Connect-CbcServer -Server "https://t2.te/" -Org "test2" -Token "test2" } | Should -Throw

			$global:CBC_CONFIG.sessionConnections.Count | Should -Be 0
			$global:defaultCbcServers.Count | Should -Be 1
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

			$Uri = "https://t.te/"
			$Org = "test"
			$secureToken = "test" | ConvertTo-SecureString -AsPlainText
			$global:CBC_CONFIG.sessionConnections.Add([CbcServer]::new($Uri,$Org,$secureToken))

			Connect-CbcServer -Menu

			$global:defaultCbcServers.Count | Should -Be 1
			$global:defaultCbcServers.Uri | Should -Be "https://t.te/"
		}

		It 'Should choose the second server and connect to it successfully' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				"2"
			}

			$Uri = "https://t.te/"
			$Org = "test"
			$secureToken = "test" | ConvertTo-SecureString -AsPlainText
			$Uri2 = "https://t2.te/"
			$Org2 = "test2"
			$secureToken2 = "test2" | ConvertTo-SecureString -AsPlainText
			$global:CBC_CONFIG.sessionConnections.Add([CbcServer]::new($Uri,$Org,$secureToken))
			$global:CBC_CONFIG.sessionConnections.Add([CbcServer]::new($Uri2,$Org2,$secureToken2))

			Connect-CbcServer -Menu

			$global:defaultCbcServers.Count | Should -Be 1
			$global:defaultCbcServers[0].Uri | Should -Be $Uri2
		}

		It 'Should not choose any server and throw error' {
			Mock -ModuleName "PSCarbonBlackCloud" -CommandName "Read-Host" -MockWith {
				"q"
			}

			$Uri = "https://t.te/"
			$Org = "test"
			$secureToken = "test" | ConvertTo-SecureString -AsPlainText
			$global:CBC_CONFIG.sessionConnections.Add([CbcServer]::new($Uri,$Org,$secureToken))
			
			{ Connect-CbcServer -Menu } | Should -Throw

			$global:defaultCbcServers.Count | Should -Be 0
		}

		It 'Should throw error as no default servers' {
			{ Connect-CbcServer -Menu -ErrorAction Stop } | Should -Throw
		}
	}

	Context "When using the 'credential' parameter set" {
		BeforeAll {
			Mock Invoke-CBCRequest -ModuleName PSCarbonBlackCloud {
				@{
					StatusCode = 200
				}
			}
		}
		
		It 'Should assign org, read the token from host input and connect to a server successfully' {
			$Org = "test"
			$password = ConvertTo-SecureString 'testToken' -AsPlainText -Force
			$credential = New-Object System.Management.Automation.PSCredential ($Org, $password)
			Mock Get-Credential -MockWith {	
				$credential
			}
			$Uri = "https://t.te/"
			$Notes = " Test server"
			
			$server = Connect-CbcServer -Server $Uri -Credential $credential -Notes $Notes

			$server.GetType() | Should -Be "CbcServer"
			$server.Uri | Should -Be $Uri
			$server.Org | Should -Be $Org
			$server.Notes | Should -Be $Notes

			$global:defaultCbcServers.Count | Should -Be 1
			$global:defaultCbcServers.Uri | Should -Be $server.Uri
			$global:defaultCbcServers.Org | Should -Be $server.Org
			$global:defaultCbcServers.Notes | Should -Be $server.Notes
		}

		It 'Shoud connect to server successfully with provided $PSCredential' {
			$Uri = "https://t.te/"
			$Org = "test"
			Mock Get-Credential -MockWith {
				$password = ConvertTo-SecureString 'testToken' -AsPlainText -Force
				$credential = New-Object System.Management.Automation.PSCredential ($Org, $password)
				$credential
			}

			$Uri = "https://t.te/"
			$cred = Get-Credential
			$server = Connect-CbcServer -Server $Uri -Credential $cred

			$server.GetType() | Should -Be "CbcServer"
			$server.Uri | Should -Be $Uri
			$server.Org | Should -Be $Org
			

			$global:defaultCbcServers.Count | Should -Be 1
			$global:defaultCbcServers.Uri | Should -Be $server.Uri
			$global:defaultCbcServers.Org | Should -Be $server.Org
		}
	}
}
