# Sourcing all the functions
$DotSourceParams = @{
	Filter = '*.ps1'
	Recurse = $true
	ErrorAction = 'Stop'
}

$Public = @(Get-ChildItem -Path "$PSScriptRoot/Public" @DotSourceParams)
$Private = @(Get-ChildItem -Path "$PSScriptRoot/Private" @DotSourceParams)
$Classes = @(Get-ChildItem -Path "$PSScriptRoot/Classes" @DotSourceParams)


foreach ($File in @($Public + $Private + $Classes)) {
	.$File.FullName
}

Export-ModuleMember -Function $Public.BaseName

# Load Endpoints
$Endpoints = Import-PowerShellDataFile -Path $PSScriptRoot/PSCarbonBlackCloudEndpoints.psd1

# Setting the Configuration Variables
$ConnectionsPath = "${Home}/.carbonblack/PSConnections.xml"
$Connections = [CbcConnections]::new($ConnectionsPath)

$DefaulCbcServers = [System.Collections.ArrayList]@()

# Set the default Global options
$CBCConfigObject = @{
	sessionConnections = [System.Collections.ArrayList]@()
	savedConnections = $Connections
	endpoints = $Endpoints
}

# Add the existing CBC servers if any from the `PSConnections.xml` file
Select-Xml -Path $ConnectionsPath -XPath '/CBCServers/CBCServer' | ForEach-Object {
	$SecureStringToken = $_.Node.Token | ConvertTo-SecureString
	$CBCConfigObject.sessionConnections.Add(
		@{	
			Uri = $_.Node.Uri
			Token = $secureStringToken
			Org = $_.Node.Org
			Notes = $_.Node.Notes
		}
	)
}


Set-Variable -Name CBC_CONFIG -Value $CBCConfigObject -Scope global
Set-Variable -Name DefaultCbcServers -Value $DefaulCbcServers -Scope global