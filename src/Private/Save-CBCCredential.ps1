function Save-CBCCredential {
    Param(
        [Parameter(Mandatory = $true)]
        $ServerObject
    )

    Process {
        $credentialsDoc = New-Object System.Xml.XmlDocument
        $credentialsDoc.Load($CBC_CONFIG.credentialsFullPath)

        $serverElement = $credentialsDoc.CreateElement("Server")
        $serverElement.SetAttribute("Uri", $ServerObject.Uri)
        $serverElement.SetAttribute("Org", $ServerObject.Org)
        $serverElement.SetAttribute("Token", $ServerObject.Token)

        $serversNode = $credentialsDoc.SelectSingleNode("Servers")
        $serversNode.AppendChild($serverElement)

        $credentialsDoc.Save($CBC_CONFIG.credentialsFullPath)
    }
}