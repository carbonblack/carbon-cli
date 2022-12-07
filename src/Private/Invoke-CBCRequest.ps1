using module ../PSCarbonBlackCloud.Classes.psm1
function Invoke-CBCRequest {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [CBCServer] $CBCServer,

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
            "X-AUTH-TOKEN" = $CBCServer.Token
            "Content-Type" = "application/json"
            "User-Agent"   = "PSCarbonBlackCloud"
        }
       
        $Params = , $CBCServer.Org + $Params
        $formatted_uri = $Endpoint -f $Params

        $FullUri = $CBCServer.Uri + $formatted_uri
        Write-Debug "Requesting ${FullUri}"
        try {
            $response = Invoke-WebRequest -Uri $FullUri -Headers $headers -Method $Method -Body $Body
            return $response
        }
        catch {
            $StatusCode = $_.Exception.Response.StatusCode
            Write-Error "Request to ${FullUri} failed. Status Code: ${StatusCode}"
        }
        return $null
    }  
}