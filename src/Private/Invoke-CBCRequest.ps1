function Invoke-CBCRequest {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject] $Server,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $Endpoint,

        [Parameter(Mandatory = $true, Position = 2)]
        [string] $Method,

        [array] $Params,

        [System.Object] $Body
    )
    
    Process {
        $headers = @{
            "X-AUTH-TOKEN" = $Server.Token
            "Content-Type" = "application/json"
            "User-Agent" = "PSCarbonBlackCloud"
        }
       
        $Params = , $Server.Org + $Params
        $formatted_uri = $Endpoint -f $Params

        $FullUri = $Server.Uri + $formatted_uri
        Write-Debug "Requesting ${FullUri}"
        return Invoke-WebRequest -Uri $FullUri -Headers $headers -Method $Method -Body $Body
    }  
}