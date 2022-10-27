function Invoke-CBCRequest {
    <#
    .ForwardHelpTargetName
        Microsoft.PowerShell.Utility\Invoke-WebRequest
    .ForwardHelpCategory
        Cmdlet
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Uri, 

        [Parameter(Mandatory = $true, Position = 1)]
        [Microsoft.PowerShell.Commands.WebRequestMethod] $Method,

        [array] $Params,

        [ValidateNotNull()]
        [X509Certificate] $Certificate,

        [switch] $SkipCertificateCheck,

        [System.Collections.IDictionary] ${Headers},

        [Microsoft.PowerShell.Commands.WebSslProtocol] $SslProtocol,

        [string] $UserAgent,

        [switch] $DisableKeepAlive,

        [ValidateRange(0, 20)]
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
    
    Process {

        $requestObjects = [System.Collections.ArrayList]@()
    
        $CBC_CONFIG.currentConnections | ForEach-Object {
            $PSBoundParameters["Headers"] = @{}
            $PSBoundParameters["Headers"]["X-AUTH-TOKEN"] = $_.Token
            $PSBoundParameters["Headers"]["Content-Type"] = "application/json"
            $PSBoundParameters["Headers"]["User-Agent"] = "PSCarbonBlackCloud"
            $PSBoundParameters["Body"] = $PSBoundParameters["Body"] | ConvertTo-Json
            $PSBoundParameters["Uri"] = ($_.Uri + $Uri) -f $_.Org, ($Params -Join ',')
            $PSBoundParameters.Remove("Params")
            $response = Invoke-WebRequest @PSBoundParameters
            $requestObjects.Add($response) | Out-Null
        }

        $requestObjects

    }
    
}