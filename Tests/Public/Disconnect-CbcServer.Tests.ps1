using module ..\..\CarbonCLI\CarbonCLI.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name CarbonCLI -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\CarbonCLI\CarbonCLI.psm1 -Force
}

AfterAll {
	Remove-Module -Name CarbonCLI -Force
}

Describe "Disconnect-CbcServer" {
	BeforeAll {
		
		$Uri1 = "https://t.te1/"
		$Org1 = "test1"
		$secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
		$Uri2 = "https://t.te2/"
		$Org2 = "test2"
		$secureToken2 = "test2" | ConvertTo-SecureString -AsPlainText
		$Uri3 = "https://t.te3/"
		$Org3 = "test3"
		$secureToken3 = "test3" | ConvertTo-SecureString -AsPlainText

		$s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
		$s2 = [CbcServer]::new($Uri2, $Org2, $secureToken2)
		$s3 = [CbcServer]::new($Uri3, $Org3, $secureToken3)
	}

	BeforeEach {
		$global:CBC_CONFIG.sessionConnections = [System.Collections.ArrayList]@()
		$global:DefaultCbcServers = [System.Collections.ArrayList]@()
	}

	It 'Should disconnect all servers' {
		$global:DefaultCbcServers.Add($s1) | Out-Null
		$global:DefaultCbcServers.Add($s2) | Out-Null

		Disconnect-CbcServer *
		$global:DefaultCbcServers.Count | Should -Be 0
	}

	It 'Should disconnect an object connection' {
		$global:DefaultCbcServers.Add($s1)
		$global:DefaultCbcServers.Add($s2)

		Disconnect-CbcServer $s1
		$global:DefaultCbcServers.Count | Should -Be 1
		$global:DefaultCbcServers[0].Uri | Should -Be $s2.Uri
	}

	It 'Should disconnect array of objects' {
		$global:DefaultCbcServers.Add($s1)
		$global:DefaultCbcServers.Add($s2)

		Disconnect-CbcServer @($s1, $s2)
		$global:DefaultCbcServers.Count | Should -Be 0
	}

	It 'Should disconnect a string connection' {
		$global:DefaultCbcServers.Add($s1)
		$global:DefaultCbcServers.Add($s2)

		Disconnect-CbcServer $s1.Uri
		$global:DefaultCbcServers.Count | Should -Be 1
		$global:DefaultCbcServers[0].Uri | Should -Be $s2.Uri
	}

	It 'Should disconnect an array of strings' {
		$global:DefaultCbcServers.Add($s1)
		$global:DefaultCbcServers.Add($s2)
		$global:DefaultCbcServers.Add($s3)

		Disconnect-CbcServer @($s1.Uri, $s2.Uri)
		$global:DefaultCbcServers.Count | Should -Be 1
		$global:DefaultCbcServers[0].Uri | Should -Be $s3.Uri
	}

	It 'Should disconnect empty array of objects' {
		$global:DefaultCbcServers.Add($s1)
		$global:DefaultCbcServers.Add($s2)
		{Disconnect-CbcServer @() -ErrorAction Stop} | Should -Throw
	}
}
