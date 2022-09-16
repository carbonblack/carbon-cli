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
        [Parameter(Mandatory = $true, Position = 0)]
        [string] ${Server},

        [Parameter(Mandatory = $false, Position = 1)]
        [securestring] ${Token},

        [Parameter(Mandatory = $false, Position = 2)]
        [string] ${Org},

        [Parameter(Mandatory = $false, Position = 3)]
        [switch] ${NotDefault},

        [Parameter(Mandatory = $false, Position = 4)]
        [pscredential] ${Credential},

        [Parameter(Mandatory = $false, Position = 5)]
        [switch] ${SaveCredentials},

        [Parameter(Mandatory = $false, Position = 6)]
        [switch] ${Menu}
    )
}