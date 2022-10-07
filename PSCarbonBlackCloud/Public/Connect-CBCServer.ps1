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
    Param (
        [Parameter(ParameterSetName = "default", Mandatory = $true, Position = 0)]
        [string] ${Server},

        [Parameter(ParameterSetName = "default", Position = 1)]
        [string] ${Org},

        [Parameter(ParameterSetName = "default", Position = 2)]
        [string] ${Token},

        [Parameter(ParameterSetName = "default")]
        [switch] ${SaveCredentials},

        [Parameter(ParameterSetName = "Menu")]
        [switch] ${Menu}
    )

    Begin {

        $ServerObject = [PSCustomObject]@{
            Server = $Server
            Org    = $Org
            Token  = $Token
        }

        # Check current connections
        if (-Not (Test-Path variable:global:CBC_CURRENT_CONNECTIONS)) {
            $emptyArray = [System.Collections.ArrayList]@()
            Set-Variable CBC_CURRENT_CONNECTIONS -Value $emptyArray -Scope Global
        }
        else {
            if ($CBC_CURRENT_CONNECTIONS.Length -ge 1) {
                $connectedServersOutput = ""
                $CBC_CURRENT_CONNECTIONS | ForEach-Object -Begin { $i = 1 } {
                    if ($_.Server -eq $Server) {
                        Write-Warning "You are already connected to that server!"
                        Exit
                    }
                    $connectedServersOutput += "[$i] " + $_.Server + "`n"
                    $i++
                }
                Write-Warning "You are currently connected to: "
                Write-Host $connectedServersOutput
                Write-Warning "If you wish to disconnect the currently connected servers, please use Disconnect-CBCServer cmdlet."
                Write-Warning "If you wish to continue connecting to new servers press [Enter] or 'Q' to quit."
                $option = Read-Host
                if ($option -eq 'q' -Or $option -eq 'Q') { 
                    Exit
                }
            }
        }

        Set-Variable CBC_CREDENTIALS_FILENAME -Option ReadOnly -Value "PSCredentials.json"

        # Different processing for `$CBC_CREDENTIALS_PATH` for the different OSs
        if ($IsLinux -Or $IsMacOS) {
            Set-Variable CBC_CREDENTIALS_PATH -Option ReadOnly -Value "${Home}/.carbonblack/"

            # Trying to create the files/directories if `-SaveCredentials` is presented
            if ($SaveCredentials.IsPresent) {
                if (-Not (Test-Path -Path $CBC_CREDENTIALS_PATH)) {
                    try {
                        New-Item -Path $CBC_CREDENTIALS_PATH -Type Directory | Write-Debug
                    }
                    catch {
                        Write-Error -Message "Cannot create directory $CBC_CREDENTIALS_PATH"
                        Exit
                    }
                }
                if (-Not (Test-Path -Path "$CBC_CREDENTIALS_PATH/$CBC_CREDENTIALS_FILENAME")) {
                    Try {
                        New-Item -Path $CBC_CREDENTIALS_PATH/$CBC_CREDENTIALS_FILENAME | Write-Debug
                    }
                    Catch {
                        Write-Error -Message "Cannot create file $CBC_CREDENTIALS_FILENAME in $CBC_CREDENTIALS_PATH"
                        Exit
                    }
                }
            }
        }
        else {
            # Windows logic for `$CBC_CREDENTIALS_PATH`
            # TODO
            Set-Variable CBC_CREDENTIALS_PATH -Option ReadOnly -Value "TODO"
        }
        Set-Variable CBC_CREDENTIALS_FULL_PATH -Option ReadOnly -Value "$CBC_CREDENTIALS_PATH/$CBC_CREDENTIALS_FILENAME"

        Test Connection
        Try {
            $checkRequest = Invoke-WebRequest -Uri $ServerObject.Server -TimeoutSec 20
            if (-Not ($checkRequest.StatusCode -eq 200)) {
                Write-Error -Message "Cannot connect to ${ServerObject.Server}: $checkRequest.StatusCode"
                Exit
            }
        }
        Catch {
            Write-Error -Message "Cannot connect to ${ServerObject.Server}"
            Exit
        }
        
        # Pre-Fill the CBC_DEFAULT_SERVERS global variable if any
        if (-Not (Test-Path variable:global:CBC_DEFAULT_SERVERS)) {
            $emptyArray = [System.Collections.ArrayList]@()
            Set-Variable CBC_DEFAULT_SERVERS -Value $emptyArray -Scope Global
        }
        else {
            $existingServers = [System.Collections.ArrayList](Get-Content $CBC_CREDENTIALS_FULL_PATH | ConvertFrom-Json -NoEnumerate)
            Set-Variable CBC_DEFAULT_SERVERS -Value $existingServers -Scope Global
        }
    }       
   
    Process {      
        
        switch ($PSCmdlet.ParameterSetName) {
            "default" {
                if (-Not $ServerObject.Org) {
                    $ServerObject.Org = Read-Host "Enter your Org Key"
                }
                if (-Not $ServerObject.Token) {
                    $ServerObject.Token = Read-Host "Enter your Token"
                }
                if ($SaveCredentials.IsPresent) {
                    $CBC_DEFAULT_SERVERS.Add($ServerObject) | Out-Null
                    (ConvertTo-Json $CBC_DEFAULT_SERVERS) > $CBC_CREDENTIALS_FULL_PATH
                }
            }
            'Menu' {
                Write-Host "Select a server from the list (by typing its number and pressing Enter): "
                $CBC_DEFAULT_SERVERS | ForEach-Object -Begin { $i = 1 } { 
                    Write-Host "[$i] $($_.Server)"
                    $i++
                }
                Try {
                    [int]$option = Read-Host
                    $ServerObject = $CBC_DEFAULT_SERVERS[$option - 1]

                    # Check if we are already connected to the server
                    $CBC_CURRENT_CONNECTIONS | ForEach-Object -Begin { $i = 1 } {
                        if ($_.Server -eq $ServerObject.Server) {
                            Write-Warning "You are already connected to that server!"
                            Exit
                        }
                    }
                }
                Catch {
                    Write-Error "Please supply an integer!"
                    Exit
                }
                
            }
        }

        $CBC_CURRENT_CONNECTIONS.Add($ServerObject) | Out-Null

        return $ServerObject
    }
}