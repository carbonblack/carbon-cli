function Test-CBCConnection {
    Param(
        [Parameter(Mandatory = $true)]
        $ServerObject
    )

    Process {
        Try {
            $checkRequest = Invoke-WebRequest -Uri $ServerObject.Uri -TimeoutSec 20
            if (-Not ($checkRequest.StatusCode -eq 200)) {
                return $false
            }
        }
        Catch {
            return $false
        }
        return $true
    }

}