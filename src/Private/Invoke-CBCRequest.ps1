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
    
        $CBC_CONFIG.currentConnections | ForEach-Object {
            $headers = [System.Collections.IDictionary]@{}
            $headers["X-AUTH-TOKEN"] = $_.Token
            $headers["Content-Type"] = "application/json"
            $headers["User-Agent"] = "PSCarbonBlackCloud"
           
            $Params = , $_.Org + $Params
            $formatted_uri = $Uri -f $Params

            $FullUri = $_.Uri + $formatted_uri
            
            try {
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