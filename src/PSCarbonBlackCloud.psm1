# Sourcing all the functions
$DotSourceParams = @{
	Filter = '*.ps1'
	Recurse = $true
	ErrorAction = 'Stop'
}

$Public = @(Get-ChildItem -Path "$PSScriptRoot\Public" @DotSourceParams)
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private" @DotSourceParams)
$Classes = @(Get-ChildItem -Path "$PSScriptRoot\Classes" @DotSourceParams)


foreach ($File in @($Public + $Private + $Classes)) {
	.$File.FullName
}

Export-ModuleMember -Function $Public.BaseName

# Load Endpoints
$Endpoints = Import-PowerShellDataFile -Path $PSScriptRoot\PSCarbonBlackCloudEndpoints.psd1

# Setting the Configuration Variables
$CredentialsPath = "${Home}\.carbonblack\PSCredentials.xml"
$Credentials = [CBCCredentials]::new($CredentialsPath)

# Set the default Global options
$CBCConfigObject = @{
	currentConnections = [System.Collections.ArrayList]@()
	defaultServers = [System.Collections.ArrayList]@()
	credentials = $Credentials
	endpoints = $Endpoints
}

# Add the existing CBC servers if any from the `PSCredentials.xml` file
Select-Xml -Path $CredentialsPath -XPath '/CBCServers/CBCServer' | ForEach-Object {
	$CBCConfigObject.defaultServers.Add(
		@{
			Uri = $_.Node.Uri
			Token = $_.Node.Token
			Org = $_.Node.Org
		}
	)
}

Set-Variable -Name CBC_CONFIG -Value $CBCConfigObject -Scope global
