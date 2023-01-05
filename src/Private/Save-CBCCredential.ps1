using module ../PSCarbonBlackCloud.Classes.psm1
function Save-CBCCredential {
  param(
    [Parameter(Mandatory = $true)]
    [CBCServer]$CBCServerObject
  )

  process {
    $credentialsDoc = New-Object System.Xml.XmlDocument
    if (Test-Path -Path $CBC_CONFIG.credentialsFullPath) {
      $credentialsDoc.Load($CBC_CONFIG.credentialsFullPath)
    }
    else {
      New-Item -Path $CBC_CONFIG.credentialsFullPath
      # Add root element
      Add-Content -Path $CBC_CONFIG.credentialsFullPath "<CBCServers>"
      Add-Content -Path $CBC_CONFIG.credentialsFullPath "</CBCServers>"
      # Load file
      $credentialsDoc.Load($CBC_CONFIG.credentialsFullPath)
    }

    $serverElement = $credentialsDoc.CreateElement("CBCServer")
    $serverElement.SetAttribute("Uri",$CBCServerObject.Uri)
    $serverElement.SetAttribute("Org",$CBCServerObject.Org)
    $serverElement.SetAttribute("Token",$CBCServerObject.Token)

    $serversNode = $credentialsDoc.SelectSingleNode("CBCServers")
    $serversNode.AppendChild($serverElement)
    $credentialsDoc.Save($CBC_CONFIG.credentialsFullPath)
  }
}
