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
        [Parameter(Mandatory = $true, Position = 0)]
        [string] ${Server},

        [Parameter(Position = 1)]
        [string] ${Org},

        [Parameter(Position = 2)]
        [string] ${Token},

        [Parameter()]
        [switch] ${SaveCredentials},

        [Parameter(ParameterSetName = "Menu")]
        [switch] ${Menu}
    )
   
    Process {

        # TODO: Set CBCCredentialsWINDOWSPath
        Set-Variable CBCCredentialsUNIXPath -Option ReadOnly -Value "${Home}/.carbonblack/PSCredentials.json"
        
        switch ($PSCmdlet.ParameterSetName) {
            default {
                if (!$Org || !$Token) {
                    $CredsTable = Find-Credentials -Server $Server -Path $CBCCredentialsUNIXPath
                    if ($CredsTable.Count -eq 0) {
                        $Org = Read-Host -Prompt 'Please supply Org Key'
                        $Token = Read-Host -Prompt 'Please supply Token'
                    } else {
                        $Org = $CredsTable["org"]
                        $Token = $CredsTable["token"]
                    }
                }
                if ($SaveCredentials.IsPresent) {
                    Add-CredentialToFile $Server $Org $Token
                }
            }
            'Menu' {
                Write-Host $CBCCredentialsUNIXPath
                break
            }
        }
        Set-Variable -Name CBC_AUTH_SERVER -Value $Server -Scope Global
        Set-Variable -Name CBC_AUTH_ORG_KEY -Value $Org -Scope Global
        Set-Variable -Name CBC_AUTH_TOKEN_KEY -Value $Token -Scope Global
    }
}