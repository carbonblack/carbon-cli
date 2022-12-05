<#
.DESCRIPTION
This cmdlet removes all or a specific connection from the CBC_CURRENT_CONNECTIONS.
.PARAMETER CBCServer
Specifies the server you want to disconnect. It accepts '*' for all servers, server name,
array of server names or CBCServer object.
.OUTPUTS
.NOTES
-------------------------- Example 1 --------------------------
Disconnect-CBCServer *
It disconnects all current connections.

-------------------------- Example 2 --------------------------
$ServerObj = Connect-CBCServer -CBCServer ""https://dev01.io/" -Org "1234" -Token "5678"
$ServerObj1 = Connect-CBCServer -CBCServer ""https://dev02.io/" -Org "1234" -Token "5678"
Disconnect-CBCServer $ServerObj, $ServerObj1
It disconnects the specified Server Objects from the current connections.

-------------------------- Example 3 --------------------------
Disconnect-CBCServer "https://dev01.io/", "https://dev02.io/"
It searches for CBC Servers with this names from the current connections and disconnects them.
.LINK
API Documentation: http://devnetworketc/
#>
function Disconnect-CBCServer {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $CBCServer
    )

    if ($CBCServer -eq '*') {
        $CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
    }
    elseif ($CBCServer -is [array]) {
        if ($CBCServer.Count -eq 0) {
            Write-Error "Empty array" -ErrorAction "Stop"
        }

        # array of Hashtables
        if ($CBCServer[0] -is [PSCustomObject]) {
            $CBCServer | ForEach-Object {
                $CBC_CONFIG.currentConnections.Remove($_)
            }
        }

        # array of Strings
        if ($CBCServer[0] -is [string]) {
            foreach ($s in $CBCServer) {
                $tmpCurrentConnections = $CBC_CONFIG.currentConnections | Where-Object { $_.Uri -eq $s }
                foreach ($c in $tmpCurrentConnections) {
                    $CBC_CONFIG.currentConnections.Remove($c)
                }
            }
        }
    }
    elseif ($CBCServer -is [PSCustomObject]) {
        $CBC_CONFIG.currentConnections.Remove($CBCServer)
    }
    elseif ($CBCServer -is [string]) {
        $tmpCurrentConnections = $CBC_CONFIG.currentConnections | Where-Object { $_.Uri -eq $CBCServer }
        foreach ($c in $tmpCurrentConnections) {
            $CBC_CONFIG.currentConnections.Remove($c)
        }
    }
}