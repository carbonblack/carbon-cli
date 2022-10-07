<#
.DESCRIPTION
This cmdlet removes all or a specific connection from the CBC_CURRENT_CONNECTIONS. 
.PARAMETER Server
Specifies the server you want to disconnect. It accepts '*' for all servers, server name,
array of server names or Server object.
.OUTPUTS

.LINK
Online Version: http://devnetworketc/
#>
function Disconnect-CBCServer {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $Server
    )

    if ($Server -eq '*') {
        Remove-Variable -Name CBC_CURRENT_CONNECTIONS -Scope Global
    }
    elseif ($Server -is [array]) {
        $CBC_CURRENT_CONNECTIONS | ForEach-Object -Begin { $i = 0 } {
            foreach ($s in $Server) {
                if ($_.Server -eq $s) {
                    $CBC_CURRENT_CONNECTIONS.RemoveAt($i)
                }
            }
            $i++
        }   
    }
    elseif ($Server -is [System.Management.Automation.PSCustomObject]) {
        $CBC_CURRENT_CONNECTIONS | ForEach-Object -Begin { $i = 0 } {
            if ($_.Server -eq $Server.server) {
                $CBC_CURRENT_CONNECTIONS.RemoveAt($i)
            }
            $i++
        }
    }
    else {
        $CBC_CURRENT_CONNECTIONS | ForEach-Object -Begin { $i = 0 } {
            if ($_.Server -eq $Server) {
                $CBC_CURRENT_CONNECTIONS.RemoveAt($i)
            }
            $i++
        }   
    }
    
}