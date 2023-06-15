using module ../PSCarbonBlackCloud.Classes.psm1

<#
.DESCRIPTION
This cmdlet removes all or a specific connection from the CBC_CURRENT_CONNECTIONS.
.PARAMETER CbcServer
Specifies the server you want to disconnect. It accepts '*' for all servers, server name,
array of server names or CbcServer object.
.EXAMPLE
PS > Disconnect-CbcServer *

It disconnects all current connections.
.EXAMPLE
PS > $ServerObj = Connect-CbcServer -Server "http://cbcserver.cbc" -Org "1234" -Token "5678"
PS > $ServerObj1 = Connect-CbcServer -Server "http://cbcserver2.cbc" -Org "1234" -Token "5678"
PS > Disconnect-CbcServer $ServerObj, $ServerObj1

It disconnects the specified Server Objects from the current connections.
.EXAMPLE
PS > Disconnect-CbcServer "http://cbcserver.cbc", "http://cbcserver2.cbc"

It searches for Cbc Servers with this names from the current connections and disconnects them.
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud
#>
function Disconnect-CbcServer {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		$CbcServer
	)

	begin {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {
		# Use case: PS > Disconnect-CbcServer *
		if ($CbcServer -eq '*') {
			$global:DefaultCbcServers = [System.Collections.ArrayList]@()
		}
		# Use case: PS > Disconnect-CbcServer array<CbcServer | string>
		elseif ($CbcServer -is [array]) {
			if ($CbcServer.Count -eq 0) {
				Write-Error "Empty array" -ErrorAction "Stop"
			}

			# If the given array is with `CbcServer` objects
			# Use case: PS > Disconnect-CbcServer $Server1, $Server2
			if ($CbcServer[0] -is [CbcServer]) {
				$CbcServer | ForEach-Object {
					$global:DefaultCbcServers.Remove($_)
				}
			}

			# If the given array is with `string` objects
			# # Use case: PS > Disconnect-CbcServer "http://cbcserver.cbc", "http://cbcserver2.cbc"
			if ($CbcServer[0] -is [string]) {
				foreach ($Server in $CbcServer) {
					$TempCurrentConnections = $global:DefaultCbcServers | Where-Object { $_.Uri -eq $Server }
					foreach ($c in $TempCurrentConnections) {
						$global:DefaultCbcServers.Remove($c)
					}
				}
			}
		}
		# Use case: PS > Disconnect-CbcServer $Server
		elseif ($CbcServer -is [CbcServer]) {
			$global:DefaultCbcServers.Remove($CbcServer)
		}
		# Use case: PS > Disconnect-CbcServer <string>
		elseif ($CbcServer -is [string]) {

			$Temp = $global:DefaultCbcServers | Where-Object { $_.Uri -eq $CbcServer }
			foreach ($c in $Temp) {
				$global:DefaultCbcServers.Remove($c)
			}
		}
	}

	end {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
	}

}
