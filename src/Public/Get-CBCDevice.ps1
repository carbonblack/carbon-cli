<#
.DESCRIPTION
This cmdlet returns all devices or a specific device with every current connection.

.PARAMETER All
Returns all devices.
.PARAMETER ID
Returns a device with specified ID.
.OUTPUTS


.LINK

Online Version: http://devnetworketc/
#>
function Get-CBCDevice {

    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName = "All")]
        [switch] $All,

        [Parameter(ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [string] $ID
    )
    Process {
        if ($CBC_CONFIG.currentConnections.Count -ge 1) {
            switch ($PSCmdlet.ParameterSetName) {
                "All" {
                    $Body = @{}
                    $response = Invoke-CBCRequest -Uri "appservices/v6/orgs/{0}/devices/_search" -Method POST -Body ($Body | ConvertTo-Json)
                }
                "ID" {
                    $response = Invoke-CBCRequest -Uri "appservices/v6/orgs/{0}/devices/{1}" -Method GET -Params @($ID) -Body ($Body | ConvertTo-Json)
                }
            }

            $result = @()
            foreach($org in ($response | Select-Object -ExpandProperty Keys)) {
                $result += $response[$org].Content | ConvertFrom-Json -AsHashtable
            }

            return $result
        }
        else {
            Write-Error "There are no current connections" -ErrorAction "Stop"
        }
    }
}