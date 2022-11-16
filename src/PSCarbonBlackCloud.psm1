# Sourcing all the functions
$dotSourceParams = @{
    Filter      = '*.ps1'
    Recurse     = $true
    ErrorAction = 'Stop'
}

Try {
    $public = @(Get-ChildItem -Path "$PSScriptRoot\Public" @dotSourceParams)
    $private = @(Get-ChildItem -Path "$PSScriptRoot\Private" @dotSourceParams)
    $classes = @(Get-ChildItem -Path "$PSScriptRoot\Classes" @dotSourceParams)
}
Catch {
    Throw $_
}

ForEach ($file in @($public + $private + $classes)) {
    Try {
        . $file.FullName
    }
    Catch {
        throw "Unable to dot source [$($file.FullName)]"
    }
}

Export-ModuleMember -Function $public.Basename

# Load Endpoints
$endpoints = Import-PowerShellDataFile -Path $PSScriptRoot\PSCarbonBlackCloudEndpoints.psd1

# Setting the Configuration Variables
$credentialsPath = "${Home}/.carbonblack/"
$credentialsFile = "PSCredentials.xml"

$cbcConfigObject = @{
    currentConnections = [System.Collections.ArrayList]@()
    defaultServers = [System.Collections.ArrayList]@()
    credentialsFullPath = ($credentialsPath + $credentialsFile)
    endpoints = $endpoints
}

# Try to initialize the credentials files
if (-Not (Test-Path -Path $credentialsPath)) {
    try {
        New-Item -Path $credentialsPath -Type Directory | Write-Debug
    }
    catch {
        Write-Error "Cannot create directory $credentialsPath" -ErrorAction "Stop"
    }
}
if (-Not (Test-Path -Path $cbcConfigObject.credentialsFullPath)) {

    Try {
        New-Item -Path $cbcConfigObject.credentialsFullPath | Write-Debug
        # Init an empty structure
        Add-Content $cbcConfigObject.credentialsFullPath "<Servers></Servers>"
    }
    Catch {
        Write-Error -Message "Cannot create file ${cbcConfigObject.credentialsFullPath}" -ErrorAction "Stop"
    }
}

# Add the existing servers if any from the `PSCredentials.xml` file
Select-Xml -Path $cbcConfigObject.credentialsFullPath -XPath '/Servers/Server' | ForEach-Object {
    $cbcConfigObject.defaultServers.Add(
        @{
            Uri = $_.Node.Uri
            Token = $_.Node.Token
            Org = $_.Node.Org
        }
    )
}

Set-Variable -Name CBC_CONFIG -Value $cbcConfigObject -Scope global