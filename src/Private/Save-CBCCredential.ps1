function Save-CBCCredential {
    Param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $ServerObject
    )

    Process {
        $credentialsDoc = New-Object System.Xml.XmlDocument
        if(Test-Path -Path $CBC_CONFIG.credentialsFullPath) {
            $credentialsDoc.Load($CBC_CONFIG.credentialsFullPath)
        }
        else {
            New-Item -Path $CBC_CONFIG.credentialsFullPath
            # Add root element
            Add-Content -Path $CBC_CONFIG.credentialsFullPath "<Servers>"
            Add-Content -Path $CBC_CONFIG.credentialsFullPath "</Servers>"
            # Load file
            $credentialsDoc.Load($CBC_CONFIG.credentialsFullPath)
        }

        $serverElement = $credentialsDoc.CreateElement("Server")
        $serverElement.SetAttribute("Uri", $ServerObject.Uri)
        $serverElement.SetAttribute("Org", $ServerObject.Org)
        $serverElement.SetAttribute("Token", $ServerObject.Token)

        # $root = $credentialsDoc.DocumentElement;

        $serversNode = $credentialsDoc.SelectSingleNode("Servers")
        #$uri = $ServerObject.Uri
        #$serverNode = $credentialsDoc.SelectSingleNode("//Server[@Uri=${uri}]")
        #if ($serverNode -eq $null) {
        #    $serversNode.AppendChild($serverElement)
        #} else {
        #    Write-Host "Found it"
        # }
        $serversNode.AppendChild($serverElement)
        $credentialsDoc.Save($CBC_CONFIG.credentialsFullPath)
    }
}