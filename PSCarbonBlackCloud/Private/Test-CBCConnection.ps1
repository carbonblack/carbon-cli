function Test-CBCConnection {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $ServerObject
    )

    Process {
        Try {
            $checkRequest = Invoke-WebRequest -Uri $ServerObject.Server -TimeoutSec 20
            if (-Not ($checkRequest.StatusCode -eq 200)) {
                Write-Error -Message "Server Status Code with: ${checkRequest.StatusCode}"
                return $false
            }
        }
        Catch {
            return $false
        }
        return $true
    }

}