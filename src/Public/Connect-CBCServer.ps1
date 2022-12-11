using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet establishes a connection to the CBC Server specified by the -CBCServer parameter.

.PARAMETER CBCServer
Specifies the IP or HTTP addresses of the CBC Server you want to connect to.
.PARAMETER Token
Specifies the Token that is going to be used in the authentication process.
.PARAMETER Org
Specifies the Organization that is going to be used in the authentication process.
.PARAMETER SaveCredentials
Indicates that you want to save the specified credentials in the local credential store.
.PARAMETER Menu
Connects to a CBC Server from the list of recently connected servers.
.OUTPUTS
A CBCServer Object

.NOTES
-------------------------- Example 1 --------------------------
Connect-CBCServer -CBCServer "http://cbcserver.cbc" -Org "MyOrg" -Token "MyToken"
Connects with the specified Server, Org, Token and returns a CBCServer Object.

-------------------------- Example 2 --------------------------
Connect-CBCServer -CBCServer "http://cbcserver1.cbc" -Org "MyOrg1" -Token "MyToken1" -SaveCredential
Connect with the specified Server, Org, Token, returns a CBCServer Object and saves the credentials in the Credential file.

-------------------------- Example 3 --------------------------
Connect-CBCServer -Menu
It prints the available CBC Servers from the Credential file so that the user can choose with which one to connect.

.LINK
API Documentation: http://devnetworketc/
#>
function Connect-CBCServer {
    [CmdletBinding(DefaultParameterSetName = "default", HelpUri = "http://devnetworketc/")]
    Param (
        [Parameter(ParameterSetName = "default", Mandatory = $true, Position = 0)]
        [Alias("CBCServer")]
        [string] ${Uri},

        [Parameter(ParameterSetName = "default", Mandatory = $true, Position = 1)]
        [string] ${Org},

        [Parameter(ParameterSetName = "default", Mandatory = $true, Position = 2)]
        [string] ${Token},

        [Parameter(ParameterSetName = "default")]
        [switch] ${SaveCredentials},

        [Parameter(ParameterSetName = "Menu")]
        [switch] $Menu
    )

    Process {
        # Show the currently connected CBC servers Warning
        If ($CBC_CONFIG.currentConnections.Count -ge 1) {
            Write-Warning "You are currently connected to: "
            $CBC_CONFIG.currentConnections | ForEach-Object {
                $index = $CBC_CONFIG.currentConnections.IndexOf($_) + 1
                $OutputMessage = "[${index}] " + $_.Uri + " Organisation: " + $_.Org
                Write-Output $OutputMessage
            }
            Write-Warning -Message "If you wish to disconnect the currently connected CBC servers, please use Disconnect-CBCServer cmdlet.`r`nIf you wish to continue connecting to new servers press any key or 'Q' to quit."
            $option = Read-Host
            if ($option -eq 'q' -Or $option -eq 'Q') {
                Write-Error "Exit" -ErrorAction "Stop"
            }
        }

        switch ($PSCmdlet.ParameterSetName) {
            "default" {
                $CBCServerObject = [CBCServer]::new()
                $CBCServerObject.Uri = $Uri
                $CBCServerObject.Org = $Org
                $CBCServerObject.Token = $Token

                if ($SaveCredentials.IsPresent) {
                    # TODO: Check if credential is already saved
                    
                    $CBC_CONFIG.defaultServers.Add($CBCServerObject) | Out-Null
                    Save-CBCCredential $CBCServerObject | Out-Null
                    
                }
            }
            "Menu" {
                if ($CBC_CONFIG.defaultServers.Count -eq 0) {
                    Write-Error "There are no default CBC servers avaliable!" -ErrorAction "Stop"
                }
                $CBC_CONFIG.defaultServers | ForEach-Object {
                    $index = $CBC_CONFIG.defaultServers.IndexOf($_) + 1
                    $OutputMessage = "[${index}] " + $_.Uri + " Organisation: " + $_.Org
                    Write-Output $OutputMessage
                }
                $optionInput = { (Read-Host) -as [int] }
                $option = & $optionInput
                if (($option -gt $CBC_CONFIG.defaultServers.Count) -or ($option -lt 0)) {
                    Write-Error "There is no default CBC server with that index" -ErrorAction "Stop"
                }
                $CBCServerObject = $CBC_CONFIG.defaultServers[$option - 1]
            }
        }

        # Check if you are currently connected to this server
        $CBC_CONFIG.currentConnections | ForEach-Object {
            if (($_.Uri -eq $CBCServerObject.Uri) -and ($_.Org -eq $CBCServerObject.Org) -and ($_.Token -eq $CBCServerObject.Token)) {
                Write-Error "You are already connected to that CBC server!" -ErrorAction "Stop"
            }
        }

        if (-Not (Test-CBCConnection $CBCServerObject)) {
            Write-Error "Cannot reach the CBC Server!" -ErrorAction "Stop"
        }

        $CBC_CONFIG.currentConnections.Add($CBCServerObject) | Out-Null
        return $CBCServerObject
    }
}
