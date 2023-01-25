class CbcServer{
	[ValidateNotNullOrEmpty()] [string]$Uri
	[ValidateNotNullOrEmpty()] [string]$Org
	[ValidateNotNullOrEmpty()] [string]$Token

	[string] ToString () {
		return "[" + $this.Org + "] " + $this.Uri
	}

	CbcServer ([string]$Uri_,[string]$Org_,[string]$Token_) {
		$this.Uri = $Uri_
		$this.Org = $Org_
		$this.Token = $Token_
	}

	[bool] IsConnected () {
		$global:CBC_CONFIG.currentConnections | ForEach-Object {
			if (($this.Uri -eq $_.Uri) -and
				($this.Org -eq $_.Org) -and
				($this.Token -eq $_.Token)) {
				return $true
			}
		}
		return $false
	}
}

class CbcCredentials{
	[string]$FullPath
	[System.Xml.XmlDocument]$XmlDocument

	CbcCredentials ([string]$FullPath) {
		$this.FullPath = $FullPath
		$DirPath = Split-Path $FullPath

		# Trying to create the dir within the path and the file itself
		if (-not (Test-Path -Path $DirPath)) {
			try {
				New-Item -Path $DirPath -Type Directory | Write-Debug
			}
			catch {
				Write-Error "Cannot create directory $(DirPath)" -ErrorAction Stop
			}
		}

		if (-not (Test-Path -Path $this.FullPath)) {
			try {
				New-Item -Path $this.FullPath | Write-Debug
				# Initialize an empty structure
				Add-Content $this.FullPath "<CBCServers></CBCServers>"
			}
			catch {
				Write-Error -Message "Cannot create file $(this.FullPath)" -ErrorAction Stop
			}
		}

		$this.XmlDocument = New-Object System.Xml.XmlDocument
		$this.XmlDocument.Load($this.FullPath)
	}

	SaveToFile ($Server) {
		try {
			$ServerElement = $this.XmlDocument.CreateElement("CBCServer")
			$ServerElement.SetAttribute("Uri",$Server.Uri)
			$ServerElement.SetAttribute("Org",$Server.Org)
			$ServerElement.SetAttribute("Token",$Server.Token)

			$ServersNode = $this.XmlDocument.SelectSingleNode("CBCServers")
			$ServersNode.AppendChild($ServerElement)
			$this.XmlDocument.Save($this.FullPath)
		}
		catch {
			Write-Error -Message "Cannot store the server to the file $(this.FullPath)"
		}
	}

	[void] RemoveFromFile ($Server) {
		$Node = $this.XmlDocument.SelectSingleNode($("//CBCServer[@Uri = '{0}'][@Org = '{1}']" -f $Server.Uri,$Server.Org))
		$Node.ParentNode.RemoveChild($Node) | Out-Null
		$this.XmlDocument.Save($this.FullPath)
	}

	[bool] IsInFile ($Server) {
		$Node = $this.XmlDocument.SelectSingleNode($("//CBCServer[@Uri = '{0}'][@Org = '{1}']" -f $Server.Uri,$Server.Org))
		if (-not $Node) {
			return $false
		}
		return $true
	}
}

class CbcDevice{

	[string]$Id
	[string]$Status
	[string]$Group
	[string]$Policy
	[string]$TargetPriority
	[string]$User
	[string]$Name
	[string]$Os
	[string]$LastContactTime
	[string]$SensorKitType
	[CbcServer]$Server
	[string]$DeploymentType
	[string]$LastDevicePolicyChangedTime
	[string]$LastDevicePolicyRequestedTime
	[string]$LastExternalIpAddress
	[string]$LastInternalIpAddress
	[string]$LastLocation
	[string]$LastPolicyUpdatedTime
	[string]$LastReportedTime
	[string]$LastResetTime
	[string]$LastShutdownTime
	[string]$MacAddress
	[string]$OrganizationId
	[string]$OrganizationName
	[string]$OsVersion
	[bool]$PassiveMode
	[string]$PolicyId
	[string]$PolicyName
	[string]$PolicyOverride
	[bool]$Quarantined
	[bool]$SensorOutOfDate
	[bool]$SensorPendingUpdate
	[string]$SensorVersion
	[string]$DeregisteredTime
	[string]$DeviceOwnerId
	[string]$RegisteredTime
	[string]$AvEngine
	[string]$AvLastScanTime
	[string]$AvStatus
	[long]$VulnerabilityScore
	[string]$VulnerabilitySeverity
	[string]$HostBasedFirewallReasons
	[string]$HostBasedFirewallStatus
	[string]$SensorGatewayUrl
	[string]$SensorGatewayUuid
	CbcDevice (
		[string]$Id_,
		[string]$Status_,
		[string]$Group_,
		[string]$Policy_,
		[string]$TargetPriority_,
		[string]$User_,
		[string]$Name_,
		[string]$Os_,
		[string]$LastContactTime_,
		[string]$SensorKitType_,
		[CbcServer]$Server_,
		[string]$DeploymentType_,
		[string]$LastDevicePolicyChangedTime_,
		[string]$LastDevicePolicyRequestedTime_,
		[string]$LastExternalIpAddress_,
		[string]$LastInternalIpAddress_,
		[string]$LastLocation_,
		[string]$LastPolicyUpdatedTime_,
		[string]$LastReportedTime_,
		[string]$LastResetTime_,
		[string]$LastShutdownTime_,
		[string]$MacAddress_,
		[string]$OrganizationId_,
		[string]$OrganizationName_,
		[string]$OsVersion_,
		[bool]$PassiveMode_,
		[string]$PolicyId_,
		[string]$PolicyName_,
		[string]$PolicyOverride_,
		[bool]$Quarantined_,
		[bool]$SensorOutOfDate_,
		[bool]$SensorPendingUpdate_,
		[string]$SensorVersion_,
		[string]$DeregisteredTime_,
		[string]$DeviceOwnerId_,
		[string]$RegisteredTime_,
		[string]$AvEngine_,
		[string]$AvLastScanTime_,
		[string]$AvStatus_,
		[long]$VulnerabilityScore_,
		[string]$VulnerabilitySeverity_,
		[string]$HostBasedFirewallReasons_,
		[string]$HostBasedFirewallStatus_,
		[string]$SensorGatewayUrl_,
		[string]$SensorGatewayUuid_
		) {
		$this.Id = $Id_
		$this.Status = $Status_
		$this.Group = $Group_
		$this.Policy = $Policy_
		$this.TargetPriority = $TargetPriority_
		$this.User = $User_
		$this.Name = $Name_
		$this.Os = $Os_
		$this.LastContactTime = $LastContactTime_
		$this.SensorKitType = $SensorKitType_
		$this.Server = $Server_
		$this.DeploymentType = $DeploymentType_
		$this.LastDevicePolicyChangedTime = $LastDevicePolicyChangedTime_
		$this.LastDevicePolicyRequestedTime = $LastDevicePolicyRequestedTime_
		$this.LastExternalIpAddress = $LastExternalIpAddress_
		$this.LastInternalIpAddress = $LastInternalIpAddress_
		$this.LastLocation = $LastLocation_
		$this.LastPolicyUpdatedTime = $LastPolicyUpdatedTime_
		$this.LastReportedTime = $LastReportedTime_
		$this.LastResetTime = $LastResetTime_
		$this.LastShutdownTime = $LastShutdownTime_
		$this.MacAddress = $MacAddress_
		$this.OrganizationId = $OrganizationId_
		$this.OrganizationName = $OrganizationName_
		$this.OsVersion = $OsVersion_
		$this.PassiveMode = $PassiveMode_
		$this.PolicyId = $PolicyId_
		$this.PolicyName = $PolicyName_
		$this.PolicyOverride = $PolicyOverride_
		$this.Quarantined = $Quarantined_
		$this.SensorOutOfDate = $SensorOutOfDate_
		$this.SensorPendingUpdate = $SensorPendingUpdate_
		$this.SensorVersion = $SensorVersion_
		$this.DeregisteredTime = $DeregisteredTime_
		$this.DeviceOwnerId = $DeviceOwnerId_
		$this.RegisteredTime = $RegisteredTime_
		$this.AvEngine = $AvEngine_
		$this.AvLastScanTime = $AvLastScanTime_
		$this.AvStatus = $AvStatus_
		$this.VulnerabilityScore = $VulnerabilityScore_
		$this.VulnerabilitySeverity = $VulnerabilitySeverity_
		$this.HostBasedFirewallReasons = $HostBasedFirewallReasons_
		$this.HostBasedFirewallStatus = $HostBasedFirewallStatus_
		$this.SensorGatewayUrl = $SensorGatewayUrl_
		$this.SensorGatewayUuid = $SensorGatewayUuid_
	}
}

class CbcPolicy{

	[string]$Id
	[string]$Name
	[string]$Description
	[string]$PriorityLevel
	[int]$NumberDevices
	[int]$Position
	[bool]$SystemEnabled

	CbcPolicy (
		[string]$Id_,
		[string]$Name_,
		[string]$Description_,
		[string]$PriorityLevel_,
		[int]$NumberDevices_,
		[int]$Position_,
		[bool]$SystemEnabled_
	) {
		$this.Id = $Id_
		$this.Name = $Name_
		$this.Description = $Description_
		$this.PriorityLevel = $PriorityLevel_
		$this.NumberDevices = $NumberDevices_
		$this.Position = $Position_
		$this.SystemEnabled = $SystemEnabled_
	}
}

class CbcAlert{

	[string]$Id
	[string]$DeviceId
	[string]$Category
	[string]$CreateTime
	[string]$FirstEventTime
	[string]$LastEventTime
	[string]$LastUpdateTime
	[hashtable]$GroupDetails
	[string]$PolicyId
	[string]$PolicyName
	[int]$Severity
	[array]$Tags
	[string]$TargetValue
	[string]$ThreatId
	[string]$Type
	[PSCustomObject]$Workflow
	[CbcServer]$Server

	CbcAlert (
		[string]$Id_,
		[string]$DeviceId_,
		[string]$Category_,
		[string]$CreateTime_,
		[string]$FirstEventTime_,
		[string]$LastEventTime_,
		[string]$LastUpdateTime_,
		[hashtable]$GroupDetails_,
		[string]$PolicyId_,
		[string]$PolicyName_,
		[int]$Severity_,
		[array]$Tags_,
		[string]$TargetValue_,
		[string]$ThreatId_,
		[string]$Type_,
		[PSCustomObject]$Workflow_,
		[CbcServer]$Server_
	) {
		$this.Id = $Id_
		$this.DeviceId = $DeviceId_
		$this.Category = $Category_
		$this.CreateTime = $CreateTime_
		$this.FirstEventTime = $FirstEventTime_
		$this.LastEventTime = $LastEventTime_
		$this.LastUpdateTime = $LastUpdateTime_
		$this.GroupDetails = $GroupDetails_
		$this.PolicyId = $PolicyId_
		$this.PolicyName = $PolicyName_
		$this.Severity = $Severity_
		$this.Tags = $Tags_
		$this.TargetValue = $TargetValue_
		$this.ThreatId = $ThreatId_
		$this.Type = $Type_
		$this.Workflow = $Workflow_
		$this.Server = $Server_
	}
}
