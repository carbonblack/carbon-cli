[CmdletBinding()]
param (
    [ValidateSet("CurrentUser", "AllUsers")]
    [string]
    $Scope = "CurrentUser",

    [string]
    $MinNugetVersion = "2.8.5.201"
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ( -not (Get-PackageProvider -Name "NuGet") ) {
    Install-PackageProvider -Name NuGet -MinimumVersion $MinNugetVersion -Force -Scope $Scope
}

$RequiredModules = Import-PowerShellDataFile -Path "./build.requirements.psd1"

Write-Output "Installing..."
foreach ($Module in $RequiredModules["requirements"]) {
    if ( -not (Get-Module -ListAvailable -Name $Module.ModuleName)) {
        Write-Output $Module.ModuleName
        Install-Module -Name $Module.ModuleName -Scope AllUsers -RequiredVersion $Module.RequiredVersion -Force -SkipPublisherCheck
    }
}

Invoke-ScriptAnalyzer -Path $PSScriptRoot\CarbonCLI\ -Recurse -ExcludeRule PSUseOutputTypeCorrectly, PSReviewUnusedParameter, PSAvoidGlobalVars, PSUseShouldProcessForStateChangingFunctions, PSUseToExportFieldsInManifest, PSUseSingularNouns
