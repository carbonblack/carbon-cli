function Convert-SecureString{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [pscredential]${Credential}
    )
    Process{
        return $Credential.GetNetworkCredential().Password
    }
}