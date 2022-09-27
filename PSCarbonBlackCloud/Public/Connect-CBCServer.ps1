<#
.DESCRIPTION
This cmdlet establishes a connection to the CBC server specified by the -Server parameter.

.PARAMETER Server
Specifies the IP or HTTP addresses of the CBC server you want to connect to. 
.PARAMETER Token
Specifies the Token that is going to be used in the authentication process.
.PARAMETER Org
Specifies the Organization that is going to be used in the authentication process.
.PARAMETER SaveCredentials
Indicates that you want to save the specified credentials in the local credential store. 
.PARAMETER Menu
Connects to a server from the list of recently connected servers.
.OUTPUTS


.LINK

Online Version: http://devnetworketc/
#>

function Connect-CBCServer {
    [CmdletBinding(HelpURI = "http://devnetworketc/")]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = "default", Position = 0)]
        [string] ${Server},

        [Parameter(ParameterSetName = "default", Position = 1)]
        [string] ${Org},

        [Parameter(ParameterSetName = "default", Position = 2)]
        [string] ${Token},

        [Parameter(ParameterSetName = "default")]
        [switch] ${SaveCredentials},

        [Parameter(ParameterSetName = "menu")]
        [switch] ${Menu}
    )
   
    Process {

        $CredsPathUnix = "${Home}/.carbonblack/PSCredentials.json"
        
        if ($Menu.IsPresent) {
            Write-Host "Using menu"
        }

        if ($SaveCredentials.IsPresent) {
            if ($null -ne $Org && $null -ne $Token) {
                Add-CredentialToFile $Server $Org $Token
            }
            else {
                Write-Host "To save the credential there must be Org and Token supplied!"
            }
        }

        if (!$Org || !$Token) {
            if (Test-Path -Path $CredsPathUnix -PathType Leaf) {
                $Credentials = (Get-Content $CredsPathUnix | ConvertFrom-Json -NoEnumerate)
                foreach ( $cred in $Credentials ) {
                    $hashtable = $cred | ConvertTo-Json | ConvertFrom-Json -AsHashTable
                    if ($hashtable["server"] -eq $Server) {
                        $Org = $hashtable["org"]
                        $Token = $hashtable["token"]
                    }
                }
                if (!$Org || !$Token) {
                    Write-Host "No server with that name"
                }
            }
            else {
                "The Credential file is empty. Please provide an Org and a Token!"
            }
            
        }
        Set-Variable -Name CBC_AUTH_SERVER -Value $Server -Scope Global
        Set-Variable -Name CBC_AUTH_ORG_KEY -Value $Org -Scope Global
        Set-Variable -Name CBC_AUTH_TOKEN_KEY -Value $Token -Scope Global
    }
}