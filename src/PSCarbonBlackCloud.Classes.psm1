class CbcServer{
	[ValidateNotNullOrEmpty()] [string]$Uri
	[ValidateNotNullOrEmpty()] [string]$Org
	[ValidateNotNullOrEmpty()] [SecureString]$Token
	[string]$Notes

	[string] ToString () {
		return "[" + $this.Org + "] " + $this.Uri
	}

	CbcServer ([string]$Uri_,[string]$Org_,[SecureString]$Token_, [string]$Notes_) {
		$this.Uri = $Uri_
		$this.Org = $Org_
		$this.Token = $Token_
		$this.Notes = $Notes_

	}

	CbcServer ([string]$Uri_,[string]$Org_,[SecureString]$Token_) {
		$this.Uri = $Uri_
		$this.Org = $Org_
		$this.Token = $Token_
		$this.Notes = ""

	}

	
	[bool] IsConnected ($defaultServers) {
		foreach ($defaultServer in $defaultServers) {
			if (($this.Uri -eq $defaultServer.Uri) -and
				($this.Org -eq $defaultServer.Org)) {
				return $true
			}
		}
		return $false
	}
}

class CbcConnections{
	[string]$FullPath
	[System.Xml.XmlDocument]$XmlDocument

	CbcConnections ([string]$FullPath) {
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
			# Convert the token to a secure string. On Win machines this will use Windows Data Encryption API to encrypt/decrypt the string
			#$secureToken = ConvertTo-SecureString $Server.Token -AsPlainText
			# Convert the secure string to a regular encrypted string so it can be stored in a file
			$secureTokenAsEncryptedString = $Server.Token | ConvertFrom-SecureString
			$ServerElement = $this.XmlDocument.CreateElement("CBCServer")
			$ServerElement.SetAttribute("Uri",$Server.Uri)
			$ServerElement.SetAttribute("Org",$Server.Org)
			$ServerElement.SetAttribute("Token",$secureTokenAsEncryptedString)
			$ServerElement.SetAttribute("Notes",$Server.Notes)

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
	[CbcServer]$Server

	CbcPolicy (
		[string]$Id_,
		[string]$Name_,
		[string]$Description_,
		[string]$PriorityLevel_,
		[int]$NumberDevices_,
		[int]$Position_,
		[bool]$SystemEnabled_,
		[CbcServer]$Server_
	) {
		$this.Id = $Id_
		$this.Name = $Name_
		$this.Description = $Description_
		$this.PriorityLevel = $PriorityLevel_
		$this.NumberDevices = $NumberDevices_
		$this.Position = $Position_
		$this.SystemEnabled = $SystemEnabled_
		$this.Server = $Server_
	}
}


class CbcPolicyDetails {

	[string]$Id
	[string]$Name
	[string]$Description
	[string]$PriorityLevel
	[int]$Position
	[bool]$SystemEnabled
	[System.Management.Automation.PSObject[]]$Rules
	[System.Management.Automation.PSObject[]]$AVSettings
	[System.Management.Automation.PSObject[]]$SensorSettings
	[System.Management.Automation.PSObject]$ManagedDetectionResponsePermissions
	[CbcServer]$Server

	CbcPolicyDetails (
		[string]$Id_,
		[string]$Name_,
		[string]$Description_,
		[string]$PriorityLevel_,
		[int]$Position_,
		[bool]$SystemEnabled_,
		[System.Management.Automation.PSObject[]]$Rules_,
		[System.Management.Automation.PSObject[]]$AVSettings_,
		[System.Management.Automation.PSObject[]]$SensorSettings_,
		[System.Management.Automation.PSObject]$ManagedDetectionResponsePermissions_,
		[CbcServer]$Server_
	) {
		$this.Id = $Id_
		$this.Name = $Name_
		$this.Description = $Description_
		$this.PriorityLevel = $PriorityLevel_
		$this.Position = $Position_
		$this.SystemEnabled = $SystemEnabled_
		$this.Rules = $Rules_
		$this.AVSettings = $AVSettings_
		$this.SensorSettings = $SensorSettings_
		$this.ManagedDetectionResponsePermissions = $ManagedDetectionResponsePermissions_
		$this.Server = $Server_
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

class CbcObservation {
	[string]$AlertCategory
	[array]$AlertId
	[string]$BackendTimestamp
	[string[]]$BlockedHash
	[string]$DeviceExternalIp
	[string]$DeviceId
	[string]$DeviceInternalIp
	[string]$DeviceOs
	[string]$DevicePolicy
	[string]$DevicePolicyId
	[string]$DeviceSensorVersion
	[string]$EventId
	[string]$ObservationId
	[string]$ObservationType
	[string[]]$ProcessCmdline
	[string]$ProcessHash
	[string]$RuleId
	[CbcServer]$Server

	CbcObservation (
		[string]$AlertCategory_,
		[array]$AlertId_,
		[string]$BackendTimestamp_,
		[string[]]$BlockedHash_,
		[string]$DeviceExternalIp_,
		[string]$DeviceId_,
		[string]$DeviceInternalIp_,
		[string]$DeviceOs_,
		[string]$DevicePolicy_,
		[string]$DevicePolicyId_,
		[string]$DeviceSensorVersion_,
		[string]$EventId_,
		[string]$ObservationId_,
		[string]$ObservationType_,
		[string]$ProcessCmdline_,
		[string]$ProcessHash_,
		[string]$RuleId_,
		[CbcServer]$Server_
	) {
		$this.AlertCategory = $AlertCategory_
		$this.AlertId = $AlertId_
		$this.BackendTimestamp = $BackendTimestamp_
		$this.BlockedHash = $BlockedHash_
		$this.DeviceExternalIp = $DeviceExternalIp_
		$this.DeviceId = $DeviceId_
		$this.DeviceInternalIp = $DeviceInternalIp_
		$this.DeviceOs = $DeviceOs_
		$this.DevicePolicy = $DevicePolicy_
		$this.DevicePolicyId = $DevicePolicyId_
		$this.DeviceSensorVersion = $DeviceSensorVersion_
		$this.EventId = $EventId_
		$this.ObservationId = $ObservationId_
		$this.ObservationType = $ObservationType_
		$this.ProcessCmdline = $ProcessCmdline_
		$this.ProcessHash = $ProcessHash_
		$this.RuleId = $RuleId_
		$this.Server = $Server_
	}
}


class CbcObservationDetails {
	[string]$AlertCategory
	[array]$AlertId
	[string]$BackendTimestamp
	[string[]]$BlockedHash
	[string]$DeviceExternalIp
	[string]$DeviceId
	[string]$DeviceInternalIp
	[string]$DeviceOs
	[string]$DevicePolicy
	[string]$DevicePolicyId
	[string]$DeviceSensorVersion
	[string]$EventId
	[string]$ObservationId
	[string]$ObservationType
	[string]$ParentCmdline
	[string[]]$ProcessCmdline
	[string]$ProcessHash
	[string]$RuleId
	[CbcServer]$Server

	CbcObservationDetails (
		[string]$AlertCategory_,
		[array]$AlertId_,
		[string]$BackendTimestamp_,
		[string[]]$BlockedHash_,
		[string]$DeviceExternalIp_,
		[string]$DeviceId_,
		[string]$DeviceInternalIp_,
		[string]$DeviceOs_,
		[string]$DevicePolicy_,
		[string]$DevicePolicyId_,
		[string]$DeviceSensorVersion_,
		[string]$EventId_,
		[string]$ObservationId_,
		[string]$ObservationType_,
		[string]$ParentCmdline_,
		[string]$ProcessCmdline_,
		[string]$ProcessHash_,
		[string]$RuleId_,
		[CbcServer]$Server_
	) {
		$this.AlertCategory = $AlertCategory_
		$this.AlertId = $AlertId_
		$this.BackendTimestamp = $BackendTimestamp_
		$this.BlockedHash = $BlockedHash_
		$this.DeviceExternalIp = $DeviceExternalIp_
		$this.DeviceId = $DeviceId_
		$this.DeviceInternalIp = $DeviceInternalIp_
		$this.DeviceOs = $DeviceOs_
		$this.DevicePolicy = $DevicePolicy_
		$this.DevicePolicyId = $DevicePolicyId_
		$this.DeviceSensorVersion = $DeviceSensorVersion_
		$this.EventId = $EventId_
		$this.ObservationId = $ObservationId_
		$this.ObservationType = $ObservationType_
		$this.ParentCmdline = $ParentCmdline_
		$this.ProcessCmdline = $ProcessCmdline_
		$this.ProcessHash = $ProcessHash_
		$this.RuleId = $RuleId_
		$this.Server = $Server_
	}
}


class CbcProcess {
	[string]$AlertCategory
	[array]$AlertId
	[string]$BackendTimestamp
	[string[]]$BlockedHash
	[string]$DeviceExternalIp
	[string]$DeviceId
	[string]$DeviceInternalIp
	[string]$DeviceOs
	[string]$DevicePolicy
	[string]$DevicePolicyId
	[string]$DeviceSensorVersion
	[string]$EventType
	[string]$ParentGuid
	[string[]]$ProcessCmdline
	[string]$ProcessGuid
	[string]$ProcessHash
	[CbcServer]$Server

	CbcProcess (
		[string]$AlertCategory_,
		[array]$AlertId_,
		[string]$BackendTimestamp_,
		[string[]]$BlockedHash_,
		[string]$DeviceExternalIp_,
		[string]$DeviceId_,
		[string]$DeviceInternalIp_,
		[string]$DeviceOs_,
		[string]$DevicePolicy_,
		[string]$DevicePolicyId_,
		[string]$DeviceSensorVersion_,
		[string]$EventType_,
		[string]$ParentGuid_,
		[string]$ProcessCmdline_,
		[string]$ProcessGuid_,
		[string]$ProcessHash_,
		[CbcServer]$Server_
	) {
		$this.AlertCategory = $AlertCategory_
		$this.AlertId = $AlertId_
		$this.BackendTimestamp = $BackendTimestamp_
		$this.BlockedHash = $BlockedHash_
		$this.DeviceExternalIp = $DeviceExternalIp_
		$this.DeviceId = $DeviceId_
		$this.DeviceInternalIp = $DeviceInternalIp_
		$this.DeviceOs = $DeviceOs_
		$this.DevicePolicy = $DevicePolicy_
		$this.DevicePolicyId = $DevicePolicyId_
		$this.DeviceSensorVersion = $DeviceSensorVersion_
		$this.EventType = $EventType_
		$this.ParentGuid = $ParentGuid_
		$this.ProcessCmdline = $ProcessCmdline_
		$this.ProcessGuid = $ProcessGuid_
		$this.ProcessHash = $ProcessHash_
		$this.Server = $Server_
	}
}

class CbcProcessDetails {
	[string]$AlertCategory
	[array]$AlertId
	[string]$BackendTimestamp
	[string[]]$BlockedHash
	[string]$DeviceExternalIp
	[string]$DeviceId
	[string]$DeviceInternalIp
	[string]$DeviceOs
	[string]$DevicePolicy
	[string]$DevicePolicyId
	[string]$EventType
	[string]$ParentCmdline
	[string]$ParentGuid
	[string[]]$ProcessCmdline
	[string]$ProcessGuid
	[string]$ProcessHash
	[CbcServer]$Server

	CbcProcessDetails (
		[string]$AlertCategory_,
		[array]$AlertId_,
		[string]$BackendTimestamp_,
		[string[]]$BlockedHash_,
		[string]$DeviceExternalIp_,
		[string]$DeviceId_,
		[string]$DeviceInternalIp_,
		[string]$DeviceOs_,
		[string]$DevicePolicy_,
		[string]$DevicePolicyId_,
		[string]$EventType_,
		[string]$ParentCmdline_,
		[string]$ParentGuid_,
		[string]$ProcessCmdline_,
		[string]$ProcessGuid_,
		[string]$ProcessHash_,
		[CbcServer]$Server_
	) {
		$this.AlertCategory = $AlertCategory_
		$this.AlertId = $AlertId_
		$this.BackendTimestamp = $BackendTimestamp_
		$this.BlockedHash = $BlockedHash_
		$this.DeviceExternalIp = $DeviceExternalIp_
		$this.DeviceId = $DeviceId_
		$this.DeviceInternalIp = $DeviceInternalIp_
		$this.DeviceOs = $DeviceOs_
		$this.DevicePolicy = $DevicePolicy_
		$this.DevicePolicyId = $DevicePolicyId_
		$this.EventType = $EventType_
		$this.ParentCmdline = $ParentCmdline_
		$this.ParentGuid = $ParentGuid_
		$this.ProcessCmdline = $ProcessCmdline_
		$this.ProcessGuid = $ProcessGuid_
		$this.ProcessHash = $ProcessHash_
		$this.Server = $Server_
	}
}

class CbcJob{
	[string]$Id
	[string]$Type
	[string]$Status
	[CbcServer]$Server

	CbcJob (
		[string]$Id_,
		[string]$Type_,
		[string]$Status_,
		[CbcServer]$Server_
	) {
		$this.Id = $Id_
		$this.Type = $Type_
		$this.Status = $Status_
		$this.Server = $Server_
	}
}
