function Set-Quarantine {
    Param(
        [Parameter(ParameterSetName = "Device", Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [array]$Device,

        [Parameter(ParameterSetName = "Id", Mandatory = $true, Position = 1)]
        [string[]] $Id,

        [PSCustomObject] $Server

    )

    Process {
        $ExecuteTo = $CBC_CONFIG.currentConnections
        if ($Server) {
            $ExecuteTo = @($Server)
        }

        $Body = @{}
        $Body["action_type"] = "QUARANTINE"
        $Body["device_id"] = $Id
        $Body["options"] = @{
            "toggle" = "ON"
        }
        switch ($PSCmdlet.ParameterSetName) {
            "Device" {
                $ids = [System.Collections.ArrayList]@()
                foreach ($device in $Device) {
                    $ids.Add($device.Id)
                }
                Write-Host $ids
                $Body["device_id"] = $ids
                $jsonBody = ConvertTo-Json -InputObject $Body
                $ExecuteTo | ForEach-Object {
                    $Response = Invoke-CBCRequest -Server $_ `
                        -Endpoint $CBC_CONFIG.endpoints["Devices"]["Quarantine"] `
                        -Method POST `
                        -Body $jsonBody
                }
            }
            "Id" {
                $jsonBody = ConvertTo-Json -InputObject $Body
                $ExecuteTo | ForEach-Object {
                    $Response = Invoke-CBCRequest -Server $_ `
                        -Endpoint $CBC_CONFIG.endpoints["Devices"]["Quarantine"] `
                        -Method POST `
                        -Body $jsonBody
                }
            }
        }
        # return $Response
    }
}