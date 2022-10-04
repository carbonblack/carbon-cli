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
            foreach ($server in $Server) {
                if ($_.Server -eq $server) {
                    $CBC_CURRENT_CONNECTIONS.RemoveAt($i)
                    # Remove-Variable -Name $CBC_CURRENT_CONNECTIONS[$i] -Scope Global
                }
            }
            $i++
        }   
    }
    else {
        $CBC_CURRENT_CONNECTIONS | ForEach-Object -Begin { $i = 0 } {
            if ($_.Server -eq $Server) {
                #Remove-Variable -Name $CBC_CURRENT_CONNECTIONS[$i] -Scope Global
                $CBC_CURRENT_CONNECTIONS.RemoveAt($i)
            }
            $i++
        }   
    }
    
}