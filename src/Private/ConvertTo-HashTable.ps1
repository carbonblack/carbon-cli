# function ConvertTo-HashTable {
# 	param(
# 		[Parameter(Mandatory = $true)]
# 		[pscustomobject]$Object
# 	)
# 	$ObjectHash = @{}
# 	($Object | Get-Member -Type NoteProperty).Name | ForEach-Object {
# 		if ($Object.$_ -is [pscustomobject]) {
# 			$ObjectHash[(ConvertTo-PascalCase $_)] = (ConvertTo-HashTable $Object.$_)
# 		}
# 		elseif ($Object.$_ -is [System.Object[]]) {
# 			$list = [System.Collections.ArrayList]@()
# 			foreach ($obj in $Object.$_) {
# 				if ($obj -is [pscustomobject]) {
# 					$list.Add((ConvertTo-HashTable $obj))
# 				}
# 				else {
# 					$list.Add($obj)
# 				}
# 			}
# 			if ($list.Count -gt 0) {
# 				$ObjectHash[(ConvertTo-PascalCase $_)] = $list
# 			}
# 		}
# 		else {
# 			$ObjectHash[(ConvertTo-PascalCase $_)] = $Object.$_
# 		}
# 	}
# 	$ObjectHash
# }
