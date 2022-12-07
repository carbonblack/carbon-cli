using module ../PSCarbonBlackCloud.Classes.psm1
function Test-CBCConnection {
    Param(
        [Parameter(Mandatory = $true)]
        [CBCServer] $CBCServerObject
    )

    Process {
        Try {
            $checkRequest = Invoke-WebRequest -Uri $CBCServerObject.Uri -TimeoutSec 20
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