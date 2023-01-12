# using module ../PSCarbonBlackCloud.Classes.psm1
# <#
# .DESCRIPTION
# This cmdlet returns an overview of the policies available in the organization.

# .PARAMETER Id
# Returns a detailed overview of a policy with the specified Id.
# .PARAMETER CBCServer
# Sets a specified CBC Server from the current connections to execute the cmdlet with.
# .OUTPUTS
# A Policy Object
# .NOTES
# -------------------------- Example 1 --------------------------
# Get-Policy
# Returns a summary of all policies and the request is made with every current connection.

# -------------------------- Example 2 --------------------------
# Get-Policy -CBCServer $ServerObj
# Returns a summary of all policies in the organisation but the request is made only with the connection with specified CBC server.

# -------------------------- Example 3 --------------------------
# Get-Policy "1234"
# Returns a detailed overview of a policy with the specified Id.

# -------------------------- Example 4 --------------------------
# Get-Policy -Id "1234"
# Returns a detailed overview of a policy with the specified Id.

# -------------------------- Example 5 --------------------------
# Get-Policy -Id "1234" -CBCServer $CBCServerObj
# Returns a detailed overview of a policy with the specified Id but the request is made only with the connection with specified CBC server.

# .LINK
# API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/platform/latest/policy-service/
# #>

# function Get-Policy {
# 	[CmdletBinding(DefaultParameterSetName = "all")]
# 	param(
# 		[Parameter(ParameterSetName = "id",Position = 0)]
# 		[array]$Id,

# 		[CBCServer]$CBCServer
# 	)

# 	process {
# 		if ($CBC_CONFIG.currentConnections) {
# 			$ExecuteTo = $CBC_CONFIG.currentConnections
# 		}
# 		else {
# 			Write-Error "There is no active connection!" -ErrorAction "Stop"
# 		}
# 		if ($CBCServer) {
# 			$ExecuteTo = @($CBCServer)
# 		}
# 		switch ($PSCmdlet.ParameterSetName) {
# 			"all" {
# 				$ExecuteTo | ForEach-Object {
# 					$CurrentCBCServer = $_
# 					$CBCServerName = "[{0}] {1}" -f $_.Org,$_.Uri
# 					$Response = Invoke-CBCRequest -CBCServer $CurrentCBCServer `
#  						-Endpoint $CBC_CONFIG.endpoints["Policy"]["Summary"] `
#  						-Method GET `

# 					Get-PolicyAPIResponse $Response $CBCServerName $CurrentCBCServer
# 				}
# 			}
# 			"id" {
# 				$ExecuteTo | ForEach-Object {
# 					$CurrentCBCServer = $_
# 					$CBCServerName = "[{0}] {1}" -f $_.Org,$_.Uri
# 					$Response = Invoke-CBCRequest -CBCServer $CurrentCBCServer `
#  						-Endpoint $CBC_CONFIG.endpoints["Policy"]["Details"] `
#  						-Method GET `
#  						-Params @($Id)

# 					Get-PolicyAPIResponse $Response $CBCServerName $CurrentCBCServer
# 				}
# 			}
# 		}
# 	}
# }
