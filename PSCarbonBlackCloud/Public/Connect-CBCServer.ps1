<#
.DESCRIPTION
This cmdlet establishes a connection to the CBC server specified by the -Server parameter.

.PARAMETER Server
Specifies the IP or HTTP addresses of the CBC server you want to connect to. 
.PARAMETER Token
Specifies the Token that is going to be used in the authentication process.
.PARAMETER Org
Specifies the Organization that is going to be used in the authentication process.
.PARAMETER NotDefault
Indicates that you do not want to save the specified servers as default servers.
.PARAMETER Credential
Specifies a PSCredential object that contains credentials for authenticating with the server.
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
        [switch] ${NotDefault},

        [Parameter(ParameterSetName = "default")]
        [pscredential] ${Credential},

        [Parameter(ParameterSetName = "default")]
        [switch] ${SaveCredentials},

        [Parameter(ParameterSetName = "menu")]
        [switch] ${Menu}
    )

    Begin {
        if($Credential -ne $null)
        {
            $Org = $Credential.UserName
            $Token = Convert-SecureString $Credential
            Set-Variable -Name ORG_KEY -Value $Org -Scope Global
            Set-Variable -Name TOKEN_KEY -Value $Token -Scope Global
        }
    }

    Process {
        if($Menu.IsPresent)
        {
            Write-Host "Using menu"
        }

        if($SaveCredentials.IsPresent)
        {
            Add-CredentialToFile $Server $Org $Token
        }

    }
}