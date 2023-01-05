# Sourcing all the functions
$dotSourceParams = @{
  Filter = '*.ps1'
  Recurse = $true
  ErrorAction = 'Stop'
}

try {
  $public = @(Get-ChildItem -Path "$PSScriptRoot\Public" @dotSourceParams)
  $private = @(Get-ChildItem -Path "$PSScriptRoot\Private" @dotSourceParams)
  $classes = @(Get-ChildItem -Path "$PSScriptRoot\Classes" @dotSourceParams)
}
catch {
  throw $_
}

foreach ($file in @($public + $private + $classes)) {
  try {
    .$file.FullName
  }
  catch {
    throw "Unable to dot source [$($file.FullName)]"
  }
}

Export-ModuleMember -Function $public.BaseName

# Load Endpoints
$endpoints = Import-PowerShellDataFile -Path $PSScriptRoot\PSCarbonBlackCloudEndpoints.psd1

# Setting the Configuration Variables
$credentialsPath = "${Home}\.carbonblack\PSCredentials.xml"
$credentials = [CBCCredentials]::new($credentialsPath)

# Set the default Global options
$cbcConfigObject = @{
  currentConnections = [System.Collections.ArrayList]@()
  defaultServers = [System.Collections.ArrayList]@()
  credentials = $credentials
  endpoints = $endpoints
}

# Add the existing CBC servers if any from the `PSCredentials.xml` file
Select-Xml -Path $credentialsPath -XPath '/CBCServers/CBCServer' | ForEach-Object {
  $cbcConfigObject.defaultServers.Add(
    @{
      Uri = $_.Node.Uri
      Token = $_.Node.Token
      Org = $_.Node.Org
    }
  )
}

Set-Variable -Name CBC_CONFIG -Value $cbcConfigObject -Scope global
