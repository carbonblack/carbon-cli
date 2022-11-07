function Invoke-CBCRequest {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Uri,

        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Method,

        [array] $Params,

        [System.Object] $Body
    )
    
    Process {

        $requestObjects = [System.Collections.ArrayList]@()
        
        if ($CBC_CONFIG.currentConnections -eq 0) {
            Write-Error "There are no current connections!" -ErrorAction Stop
        }

        $CBC_CONFIG.currentConnections | ForEach-Object {
            $headers = @{
                "X-AUTH-TOKEN" = $_.Token
                "Content-Type" = "application/json"
                "User-Agent" = "PSCarbonBlackCloud"
            }
           
            $Params = , $_.Org + $Params
            $formatted_uri = $Uri -f $Params

            $FullUri = $_.Uri + $formatted_uri
            Write-Host $FullUri
            try {
                Write-Debug "Requesting ${FullUri}"
                $response = Invoke-WebRequest -Uri $FullUri -Headers $headers -Method $Method -Body $Body
            }
            catch {
                Write-Error "ERROR ON REQUEST TO: ${FullUri}"
                Write-Error $_.Exception.Message -ErrorAction Stop
            }
            
            $requestObjects.Add(@{$_.Org = $response }) | Out-Null
        }
        $requestObjects
    }  
}