function Invoke-CBCRequest {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [System.Collections.IDictionary]$Headers,

        [Parameter(Mandatory)]
        [string]$Method

    )
    if ($CBC_USE_JWT -eq $true) {
        Write-Host "Using JWT"
    }
    elseif ($CBC_USE_AT -eq $true) {

        $credentials = Get-Credentials $Section
        $url = $credentials["url"]
        $org = $credentials["org"]
        $token = $credentials["token"]

        if ($null -eq $Headers) {
            $Headers = @{}
        }
        $Headers["X-AUTH-TOKEN"] = $token
        $Headers["Content-Type"] = "application/json"
        $Headers["User-Agent"] = "PSCarbonBlackCloud"
        

        [regex]$pattern = "{}"
        $Uri = $pattern.replace($Uri, $url, 1)
        $Uri = $pattern.replace($Uri, $org, 1)
    }

    Invoke-WebRequest -Uri $Uri -Headers $Headers -Method $Method
}