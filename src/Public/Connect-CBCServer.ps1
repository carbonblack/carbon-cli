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
    [CmdletBinding(DefaultParameterSetName = "default", HelpUri = "http://devnetworketc/")]
    [OutputType([PSCarbonBlackCloud.Server])]
    Param (
        [Parameter(ParameterSetName = "default", Mandatory = $true, Position = 0)]
        [Alias("Server")]
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
        # Show the currently connected servers Warning
        If ($CBC_CONFIG.currentConnections.Count -ge 1) {
            Write-Warning "You are currently connected to: "
            $CBC_CONFIG.currentConnections | ForEach-Object {
                $index = $CBC_CONFIG.currentConnections.IndexOf($_) + 1
                    $OutputMessage = "[${index}] " + $_.Uri + " Organisation: " + $_.Org
                    Write-Output $OutputMessage
            }
            Write-Warning -Message "If you wish to disconnect the currently connected servers, please use Disconnect-CBCServer cmdlet.`r`nIf you wish to continue connecting to new servers press any key or 'Q' to quit."
            $option = Read-Host
            if ($option -eq 'q' -Or $option -eq 'Q') {
                Write-Error "Exit" -ErrorAction "Stop"
            }
        }

        switch ($PSCmdlet.ParameterSetName) {
            "default" {
                $ServerObject = [PSCarbonBlackCloud.Server]@{
                    Uri = $Uri
                    Org = $Org
                    Token = $Token
                }

                if ($SaveCredentials.IsPresent) {
                    $CBC_CONFIG.defaultServers.Add($ServerObject) | Out-Null
                    Save-CBCCredential $ServerObject
                }
            }
            "Menu" {
                if ($CBC_CONFIG.defaultServers.Count -eq 0) {
                    Write-Error "There are no default servers avaliable!" -ErrorAction "Stop"
                }
                $CBC_CONFIG.defaultServers | ForEach-Object {
                    $index = $CBC_CONFIG.defaultServers.IndexOf($_) + 1
                    $OutputMessage = "[${index}] " + $_.Uri + " Organisation: " + $_.Org
                    Write-Output $OutputMessage
                }
                $optionInput = { (Read-Host) -as [int] }
                $option = & $optionInput
                if (($option -gt $CBC_CONFIG.defaultServers.Count) -or ($option -lt 0)) {
                    Write-Error "There is no default server with that index" -ErrorAction "Stop"
                }
                $ServerObject = $CBC_CONFIG.defaultServers[$option - 1]
            }
        }

        # Check if you are currently connected to this server
        $CBC_CONFIG.currentConnections | ForEach-Object {
            if (($_.Uri -eq $ServerObject.Uri) -and ($_.Org -eq $ServerObject.Org) -and ($_.Token -eq $ServerObject.Token)) {
                Write-Error "You are already connected to that server!" -ErrorAction "Stop"
            }
        }

        if (-Not (Test-CBCConnection $ServerObject)) {
            Write-Error "Cannot reach the server!" -ErrorAction "Stop"
        }

        $CBC_CONFIG.currentConnections.Add($ServerObject) | Out-Null
        return $ServerObject
    }
}