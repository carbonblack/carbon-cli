using module ../PSCarbonBlackCloud.Classes.psm1

<#
.DESCRIPTION
	This cmdlet removes all or a specific connection from the CBC_CURRENT_CONNECTIONS.
.PARAMETER CBCServer
	Specifies the server you want to disconnect. It accepts '*' for all servers, server name,
	array of server names or CBCServer object.
.OUTPUTS
.NOTES
	-------------------------- EXAMPLE 1 --------------------------
	PS > Disconnect-CBCServer *
	
		It disconnects all current connections.



	-------------------------- EXAMPLE 2 --------------------------
	PS > $ServerObj = Connect-CBCServer -CBCServer "http://cbcserver.cbc" -Org "1234" -Token "5678"
	PS > $ServerObj1 = Connect-CBCServer -CBCServer "http://cbcserver2.cbc" -Org "1234" -Token "5678"
	PS > Disconnect-CBCServer $ServerObj, $ServerObj1
	
		It disconnects the specified Server Objects from the current connections.



	-------------------------- EXAMPLE 3 --------------------------
	PS > Disconnect-CBCServer "http://cbcserver.cbc", "http://cbcserver2.cbc"
	
		It searches for CBC Servers with this names from the current connections and disconnects them.


.LINK
	API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud
#>
function Disconnect-CBCServer {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		$CBCServer
	)

	begin {
		Write-Verbose "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {
		# Use case: PS > Disconnect-CBCServer *
		if ($CBCServer -eq '*') {
			$CBC_CONFIG.currentConnections = [System.Collections.ArrayList]@()
		}
		# Use case: PS > Disconnect-CBCServer array<CBCServer | string>
		elseif ($CBCServer -is [array]) {
			if ($CBCServer.Count -eq 0) {
				Write-Error "Empty array" -ErrorAction "Stop"
			}

			# If the given array is with `CBCServer` objects
			# Use case: PS > Disconnect-CBCServer $Server1, $Server2
			if ($CBCServer[0] -is [CBCServer]) {
				$CBCServer | ForEach-Object {
					$CBC_CONFIG.currentConnections.Remove($_)
				}
			}

			# If the given array is with `string` objects
			# # Use case: PS > Disconnect-CBCServer "http://cbcserver.cbc", "http://cbcserver2.cbc"
			if ($CBCServer[0] -is [string]) {
				foreach ($Server in $CBCServer) {
					$TempCurrentConnections = $CBC_CONFIG.currentConnections | Where-Object { $_.Uri -eq $Server }
					foreach ($c in $TempCurrentConnections) {
						$CBC_CONFIG.currentConnections.Remove($c)
					}
				}
			}
		}
		# Use case: PS > Disconnect-CBCServer $Server
		elseif ($CBCServer -is [CBCServer]) {
			$CBC_CONFIG.currentConnections.Remove($CBCServer)
		}
		# Use case: PS > Disconnect-CBCServer <string>
		elseif ($CBCServer -is [string]) {

			$Temp = $CBC_CONFIG.currentConnections | Where-Object { $_.Uri -eq $CBCServer }
			foreach ($c in $Temp) {
				$CBC_CONFIG.currentConnections.Remove($c)
			}
		}
	}

	end {
		Write-Verbose "[$($MyInvocation.MyCommand.Name)] function finished"
	}

}
