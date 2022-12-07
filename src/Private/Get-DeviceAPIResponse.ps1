using module ../PSCarbonBlackCloud.Classes.psm1
function Get-DeviceAPIResponse {
    Param(
        $Response,

        $CBCServerName,

        $CurrentCBCServer
    )   
    Process {
        if ($null -ne $Response) {
            $ResponseContent = $Response.Content | ConvertFrom-Json
        
            Write-Host "`r`n`tDevices from: $CBCServerName`r`n"
            if ($ResponseContent.results) {
                $ResponseContent.results | ForEach-Object {
                    $CurrentDevice = $_
                    $DeviceObject = [Device]::new()
                    $DeviceObject.CBCServer = $CurrentCBCServer
                    ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                        $key = (ConvertTo-PascalCase $_)
                        $value = $CurrentDevice.$_
                        $DeviceObject.$key = $value
                    }
                    $DeviceObject 
                }
            }
            else {
                $ResponseContent | ForEach-Object {
                    $CurrentDevice = $_
                    $DeviceObject = [Device]::new()
                    $DeviceObject.CBCServer = $CurrentCBCServer
                    ($_ | Get-Member -Type NoteProperty).Name | ForEach-Object {
                        $key = (ConvertTo-PascalCase $_)
                        $value = $CurrentDevice.$_
                        $DeviceObject.$key = $value
                    }
                    $DeviceObject 
                }
            }
        } 
    }
}