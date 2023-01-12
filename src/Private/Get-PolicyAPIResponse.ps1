# using module ../PSCarbonBlackCloud.Classes.psm1
# function Get-PolicyAPIResponse {
# 	param(
# 		$Response,

# 		$CBCServerName,

# 		$CurrentCBCServer
# 	)
# 	process {
# 		if ($null -ne $Response) {
# 			$ResponseContent = $Response.Content | ConvertFrom-Json

# 			Write-Host "`r`n`tPolicy from: $CBCServerName`r`n"
# 			if ($ResponseContent.policies) {
# 				$ResponseContent.policies | ForEach-Object {
# 					$CurrentPolicy = $_
# 					$PolicyObject = [PolicySummary]::new()
# 					$PolicyObject.CBCServer = $CurrentCBCServer
# 					($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
# 						$key = (ConvertTo-PascalCase $_)
# 						$value = $CurrentPolicy.$_
# 						$PolicyObject.$key = $value
# 					}
# 					$PolicyObject
# 				}
# 			}
# 			else {
# 				$ResponseContent | ForEach-Object {
# 					$CurrentPolicy = $_
# 					$PolicyObject = [Policy]::new()
# 					$PolicyObject.CBCServer = $CurrentCBCServer
# 					($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
# 						$key = (ConvertTo-PascalCase $_)
# 						$value = $CurrentPolicy.$_
# 						if ($value -is [pscustomobject]) {
# 							$PolicyObject.$key = (ConvertTo-HashTable $value)
# 						}
# 						elseif ($value -is [System.Object[]]) {
# 							$list = [System.Collections.ArrayList]@()
# 							foreach ($obj in $value) {
# 								if ($obj -is [pscustomobject]) {
# 									($list.Add((ConvertTo-HashTable $obj))) | Out-Null
# 								}
# 								else {
# 									($list.Add($obj)) | Out-Null
# 								}
# 							}
# 							if ($list.Count -gt 0) {
# 								$PolicyObject.$key = $list
# 							}
# 						}
# 						else {
# 							$PolicyObject.$key = $value
# 						}
# 					}
# 					$PolicyObject
# 				}
# 			}
# 		}
# 	}
# }
