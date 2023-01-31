using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Disconnect-CbcServer" {

	BeforeAll {
		$s1 = [CbcServer]::new("https://t.te/","test","test")
		$s2 = [CbcServer]::new("https://t2.te/","test2","test2")
		$s3 = [CbcServer]::new("https://t3.te/","test3","test3")
	}

	BeforeEach {
		$global:CBC_CONFIG.defaultServers = [System.Collections.ArrayList]@()
		$global:CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
	}

	It 'Should disconnect all servers' {
		$global:CBC_CONFIG.currentConnections.Add($s1) | Out-Null
		$global:CBC_CONFIG.currentConnections.Add($s2) | Out-Null

		Disconnect-CbcServer *

		$global:CBC_CONFIG.currentConnections.Count | Should -Be 0
	}

	It 'Should disconnect an object connection' {
		$global:CBC_CONFIG.currentConnections.Add($s1)
		$global:CBC_CONFIG.currentConnections.Add($s2)

		Disconnect-CbcServer $s1

		$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
		$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be $s2.Uri
	}

	It 'Should disconnect array of objects' {
		$global:CBC_CONFIG.currentConnections.Add($s1)
		$global:CBC_CONFIG.currentConnections.Add($s2)

		Disconnect-CbcServer @($s1,$s2)

		$global:CBC_CONFIG.currentConnections.Count | Should -Be 0
	}

	It 'Should disconnect a string connection' {
		$global:CBC_CONFIG.currentConnections.Add($s1)
		$global:CBC_CONFIG.currentConnections.Add($s2)

		Disconnect-CbcServer $s1.Uri
		$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
		$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be $s2.Uri
	}


	It 'Should disconnect an array of strings' {
		$global:CBC_CONFIG.currentConnections.Add($s1)
		$global:CBC_CONFIG.currentConnections.Add($s2)
		$global:CBC_CONFIG.currentConnections.Add($s3)

		Disconnect-CbcServer @($s1.Uri,$s2.Uri)
		$global:CBC_CONFIG.currentConnections.Count | Should -Be 1
		$global:CBC_CONFIG.currentConnections[0].Uri | Should -Be $s3.Uri
	}

}
