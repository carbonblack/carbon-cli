function Invoke-CBCRequest {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $ApiUri, 

        [Parameter(Mandatory = $true, Position = 1)]
        [Microsoft.PowerShell.Commands.WebRequestMethod] $Method,

        [ValidateNotNull()]
        [X509Certificate] $Certificate,

        [switch] $SkipCertificateCheck,

        [System.Collections.IDictionary] ${Headers},

        [Microsoft.PowerShell.Commands.WebSslProtocol] $SslProtocol,

        [string] $UserAgent,

        [switch] $DisableKeepAlive,

        [ValidateRange(0, 2147483647)]
        [int32] $TimeoutSec,

        [ValidateRange(0, 10)]
        [int] $MaximumRedirection,

        [switch] $NoProxy,

        [uri] $Proxy,

        [pscredential]
        [System.Management.Automation.CredentialAttribute()] $ProxyCredential,

        [switch] $ProxyUseDefaultCredentials,

        [System.Object] $Body,

        [string] $ContentType,

        [ValidateSet('chunked', 'compress', 'deflate', 'gzip', 'identity')]
        [string] $TransferEncoding,

        [switch] $SkipHeaderValidation
    )

    if ($CBC_CONFIG.currentConnections.Count -ge 1) {
        $CBC_CONFIG.currentConnections | ForEach-Object {
            $url = $_.Uri
            $org = $_.Org
            $token = $_.Token

            $PSBoundParameters["Headers"]["X-AUTH-TOKEN"] = $token
            $PSBoundParameters["Headers"]["Content-Type"] = "application/json"
            $PSBoundParameters["Headers"]["User-Agent"] = "PSCarbonBlackCloud"

            $PSBoundParameters["Body"] = $PSBoundParameters["Body"] | ConvertTo-Json
            $PSBoundParameters["Uri"] = 
            $fullUrl = $url + [string]::Format($CBC_CONFIG.endpoints[$Endpoint][$EndpointMethod], $_.Org, $Id)
            try {
                Invoke-WebRequest -Uri $fullUrl -Headers $Headers -Method $Method -Body {$Body | ConvertTo-Json}
            }
            catch {
                Write-Error "Cannot reach the server!" -ErrorAction "Stop"
            }
        }
    }
    else {
        Write-Error "There are no current connections!" -ErrorAction "Stop"
    }       
}