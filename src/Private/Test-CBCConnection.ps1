using module ../PSCarbonBlackCloud.Classes.psm1
function Test-CBCConnection {
  param(
    [Parameter(Mandatory = $true)]
    [CBCServer]$CBCServerObject
  )

  process {
    try {
      $checkRequest = Invoke-WebRequest -Uri $CBCServerObject.Uri -TimeoutSec 20
      if (-not ($checkRequest.StatusCode -eq 200)) {
        return $false
      }
    }
    catch {
      return $false
    }
    return $true
  }

}
