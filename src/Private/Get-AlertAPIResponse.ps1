using module ../PSCarbonBlackCloud.Classes.psm1
function Get-AlertAPIResponse {
  param(
    $Response,

    $CBCServerName,

    $CurrentCBCServer
  )
  process {
    if ($null -ne $Response) {
      $ResponseContent = $Response.Content | ConvertFrom-Json

      Write-Host "`r`n`Alerts from: $CBCServerName`r`n"
      if ($ResponseContent.results) {
        $ResponseContent.results | ForEach-Object {
          $CurrentAlert = $_
          if ($CurrentAlert.type -eq "CB_ANALYTICS")
          {
            $AlertObject = [CBAnalyticsAlert]::new()
          }
          elseif ($CurrentAlert.type -eq "DEVICE_CONTROL") {
            $AlertObject = [DeviceControlAlert]::new()
          }
          elseif ($CurrentAlert.type -eq "WATCHLIST") {
            $AlertObject = [WatchlistAlert]::new()
          }
          else {
            $AlertObject = [ContainerRuntimeAlert]::new()
          }
          $AlertObject.CBCServer = $CurrentCBCServer
          ($CurrentAlert | Get-Member -Type NoteProperty).Name | ForEach-Object {
            $key = (ConvertTo-PascalCase $_)
            $value = $CurrentAlert.$_
            $AlertObject.$key = $value
          }
          $AlertObject
        }
      }
      else {
        $ResponseContent | ForEach-Object {
          $CurrentAlert = $_
          if ($CurrentAlert.type -eq "CB_ANALYTICS")
          {
            $AlertObject = [CBAnalyticsAlert]::new()
          }
          elseif ($CurrentAlert.type -eq "DEVICE_CONTROL") {
            $AlertObject = [DeviceControlAlert]::new()
          }
          elseif ($CurrentAlert.type -eq "WATCHLIST") {
            $AlertObject = [WatchlistAlert]::new()
          }
          else {
            $AlertObject = [ContainerRuntimeAlert]::new()
          }
          $AlertObject.CBCServer = $CurrentCBCServer
          ($CurrentAlert | Get-Member -Type NoteProperty).Name | ForEach-Object {
            $key = (ConvertTo-PascalCase $_)
            $value = $CurrentAlert.$_
            $AlertObject.$key = $value
          }
          $AlertObject
        }
      }
    }
  }
}
