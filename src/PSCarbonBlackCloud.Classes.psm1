class CBCServer{
	[ValidateNotNullOrEmpty()] [string]$Uri
	[ValidateNotNullOrEmpty()] [string]$Org
	[ValidateNotNullOrEmpty()] [string]$Token

	[string] ToString () {
		return "[" + $this.Org + "] " + $this.Uri
	}

	CBCServer ([string]$Uri_,[string]$Org_,[string]$Token_) {
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

class CBCCredentials{
	[string]$FullPath
	[System.Xml.XmlDocument]$XmlDocument

	CBCCredentials ([string]$FullPath) {
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
			$ServerElement.SetAttribute("Uri", $Server.Uri)
			$ServerElement.SetAttribute("Org", $Server.Org)
			$ServerElement.SetAttribute("Token", $Server.Token)

			$ServersNode = $this.XmlDocument.SelectSingleNode("CBCServers")
			$ServersNode.AppendChild($ServerElement)
			$this.XmlDocument.Save($this.FullPath)
		}
		catch {
			Write-Error -Message "Cannot store the server to the file $(this.FullPath)"
		}
	}

	[void] RemoveFromFile ($Server) {
		$Node = $this.XmlDocument.SelectSingleNode($("//CBCServer[@Uri = '{0}'][@Org = '{1}']" -f $Server.Uri, $Server.Org))
		$Node.ParentNode.RemoveChild($Node) | Out-Null
		$this.XmlDocument.Save($this.FullPath)
	}

	[bool] IsInFile ($Server) {
		$Node = $this.XmlDocument.SelectSingleNode($("//CBCServer[@Uri = '{0}'][@Org = '{1}']" -f $Server.Uri, $Server.Org))
		if (-not $Node) {
			return $false
		}
		return $true
	}
}


class PolicySummary{
	[long]$Id
	[switch]$IsSystem
	[string]$Name
	[string]$Description
	[string]$PriorityLevel
	[long]$Position
	[long]$NumDevices
	[CBCServer]$CBCServer
}

class DeploymentType{
	[string]$ENDPOINT = "ENDPOINT"
	[string]$WORKLOAD = "WORKLOAD"
	[string]$VDI = "VDI"
	[string]$AWS = "AWS"
}

class OS{
	[string]$WINDOWS = "WINDOWS"
	[string]$CENTOS = "CENTOS"
	[string]$RHEL = "RHEL"
	[string]$ORACLE = "ORACLE"
	[string]$SLES = "SLES"
	[string]$AMAZON_LINUX = "AMAZON_LINUX"
	[string]$SUSE = "SUSE"
	[string]$UBUNTU = "UBUNTU"
}

class SignatureStatus{
	[string]$NOT_APPLICABLE = "NOT_APPLICABLE"
	[string]$NOT_AVAILABLE = "NOT_AVAILABLE"
	[string]$UP_TO_DATE = "UP_TO_DATE"
	[string]$OUT_OF_DATE = "OUT_OF_DATE"
}

class Status{
	[string]$PENDING = "PENDING"
	[string]$REGISTERED = "REGISTERED"
	[string]$UNINSTALLED = "UNINSTALLED"
	[string]$DEREGISTERED = "DEREGISTERED"
	[string]$ACTIVE = "ACTIVE"
	[string]$INACTIVE = "INACTIVE"
	[string]$ERROR = "ERROR"
	[string]$ALL = "ALL"
	[string]$BYPASS_ON = "BYPASS_ON"
	[string]$BYPASS = "BYPASS"
	[string]$QUARANTINE = "QUARANTINE"
	[string]$SENSOR_OUTOFDATE = "SENSOR_OUTOFDATE"
	[string]$DELETED = "DELETED"
	[string]$LIVE = "LIVE"
}

class SubDeploymentType{
	[string]$VMWARE_VIRTUAL_MACHINE = "VMWARE_VIRTUAL_MACHINE"
	[string]$AWS_VIRTUAL_MACHINE_EC2 = "AWS_VIRTUAL_MACHINE_EC2"
}

class VirtualizationProvider{
	[string]$VMW_ESX = "VMW_ESX"
	[string]$VMW_WS = "VMW_WS"
	[string]$VMW_OTHER = "VMW_OTHER"
	[string]$HyperV = "HyperV"
	[string]$VirtualBox = "VirtualBox"
	[string]$AWS_EC2 = "AWS_EC2"
	[string]$OTHER = "OTHER"
}

class SensorStates{
	[string]$Active = "ACTIVE";
	[string]$PanicsDetected = "PANICS_DETECTED";
	[string]$LoopDetected = "LOOP_DETECTED";
	[string]$DbCorruptionDetected = "DB_CORRUPTION_DETECTED";
	[string]$CsrAction = "CSR_ACTION";
	[string]$RepuxAction = "REPUX_ACTION";
	[string]$DriverInitError = "DRIVER_INIT_ERROR";
	[string]$RemgrInitError = "REMGR_INIT_ERROR";
	[string]$UnsupportedOs = "UNSUPPORTED_OS";
	[string]$SensorUpgradeInProgress = "SENSOR_UPGRADE_IN_PROGRESS";
	[string]$SensorUnregistered = "SENSOR_UNREGISTERED";
	[string]$Watchdog = "WATCHDOG";
	[string]$SensorResetInProgress = "SENSOR_RESET_IN_PROGRESS";
	[string]$DriverInitRebootRequired = "DRIVER_INIT_REBOOT_REQUIRED";
	[string]$DriverLoadNotGranted = "DRIVER_LOAD_NOT_GRANTED";
	[string]$SensorShutdown = "SENSOR_SHUTDOWN";
	[string]$SensorMaintenance = "SENSOR_MAINTENANCE";
	[string]$FullDiskAccessNotGranted = "FULL_DISK_ACCESS_NOT_GRANTED";
	[string]$DebugModeEnabled = "DEBUG_MODE_ENABLED";
	[string]$AutoUpdateDisabled = "AUTO_UPDATE_DISABLED";
	[string]$SelfProtectDisabled = "SELF_PROTECT_DISABLED";
	[string]$VdiModeEnabled = "VDI_MODE_ENABLED";
	[string]$PocModeEnabled = "POC_MODE_ENABLED";
	[string]$SecurityCenterOptlnDisabled = "SECURITY_CENTER_OPTLN_DISABLED";
	[string]$LiveResponseRunning = "LIVE_RESPONSE_RUNNING";
	[string]$LiveResponseNotRunning = "LIVE_RESPONSE_NOT_RUNNING";
	[string]$LiveResponseKilled = "LIVE_RESPONSE_KILLED";
	[string]$LiveResponseNotKilled = "LIVE_RESPONSE_NOT_KILLED";
	[string]$LiveResponseEnabled = "LIVE_RESPONSE_ENABLED";
	[string]$LiveResponseDisabled = "LIVE_RESPONSE_DISABLED";
	[string]$DriverKernel = "DRIVER_KERNEL";
	[string]$DriverUserspace = "DRIVER_USERSPACE";
	[string]$DriverLoadPending = "DRIVER_LOAD_PENDING";
	[string]$OsVersionMismatch = "OS_VERSION_MISMATCH";
}

class AVStatus{
	[string]$AvNotRegistered = "AV_NOT_REGISTERED";
	[string]$AvRegistered = "AV_REGISTERED";
	[string]$AvDeregisteredAvDeregistered;
	[string]$AvActive = "AV_ACTIVE";
	[string]$AvBypass = "AV_BYPASS";
	[string]$SignatureUpdateDisabled = "SIGNATURE_UPDATE_DISABLED";
	[string]$OnaccessScanDisabled = "ONACCESS_SCAN_DISABLED";
	[string]$OndemandScanDisabled = "ONDEMAND_SCAN_DISABLED";
	[string]$ProductUpdateDisabled = "PRODUCT_UPDATE_DISABLED";
}



class Device{
	[CBCServer]$CBCServer
	[string]$CurrentSensorPolicyName
	[string]$DeploymentType

	#  TODO: This contains a list and should be changed
	[string]$DeviceMetaDataItemList

	[string]$Id
	[string]$LastContactTime
	[string]$LastDevicePolicyChangedTime
	[string]$LastDevicePolicyRequestedTime
	[string]$LastExternalIpAddress
	[string]$LastInternalIpAddress
	[string]$LastLocation
	[string]$LastPolicyUpdatedTime
	[string]$LastReportedTime
	[string]$LastResetTime
	[string]$LastShutdownTime
	[string]$LoginUserName
	[string]$MacAddress
	[string]$Name
	[string]$OrganizationId
	[string]$OrganizationName
	[string]$Os
	[string]$OsVersion
	[switch]$PassiveMode
	[int]$PolicyId
	[string]$PolicyName
	[switch]$Quarantined
	[string]$ScanLastActionTime
	[string]$SensorKitType
	[switch]$SensorOutOfDate
	[switch]$SensorPendingUpdate
	[string]$SensorStates
	[string]$SensorVersion
	[string]$Status
	[string]$TargetPriority
	[string]$VdiBaseDevice
	[int]$AdGroupId
	[switch]$PolicyOverride
	[string]$ActivationCode
	[string]$ActivationCodeExpiryTime
	[string]$DeregisteredTime
	[int]$DeviceOwnerId
	[string]$Email
	[string]$FirstName
	[string]$MiddleName
	[string]$EncodedActivationCode
	[string]$LastName
	[string]$RegisteredTime
	[string]$UninstallCode
	[string]$AvAveVersion
	[string]$AvEngine
	[string]$AvLastScanTime
	[switch]$AvMaster
	[string]$AvPackVersion
	[string]$AvProductVersion
	[string]$AvStatus

	#  TODO: This contains a list and should be changed
	[int]$AvUpdateServers

	[string]$ApplianceName
	[string]$ApplianceUuid
	[string]$ClusterName
	[string]$DatacenterName
	[string]$EsxHostName
	[string]$EsxHostUuid
	[switch]$GoldenDevice
	[int]$GoldenDeviceId
	[string]$NsxDistributedFirewallPolicy
	[switch]$NsxEnabled
	[string]$VcenterHostUrl
	[string]$VcenterName
	[string]$VcenterUuid
	[switch]$VirtualMachine
	[string]$VirtualPrivateCloudId
	[string]$VirtualizationProvider
	[string]$VmIp
	[string]$VmName
	[string]$VmUuid
	[long]$VulnerabilityScore
	[string]$VulnerabilitySeverity
	[long]$AutoScalingGroupName
	[long]$CloudProviderAccountId
	[long]$CloudProviderResourceId
	[string[]]$CloudProviderTags
	[string]$HostBasedFirewallFailureReason
	[string]$HostBasedFirewallReasons
	[string]$HostBasedFirewallStatus
	[string]$BaseDevice
	[string]$AvVdfVersion
	[string]$LinuxKernelVersion
	[string]$ScanLastCompleteTime
	[string]$ScanStatus
	[string]$WindowsPlatform
	[string]$VdiProvider
	[string]$InfrastructureProvider
	[string]$SensorGatewayUrl
	[string]$SensorGatewayUuid
}

class Policy{
	[CBCServer]$CBCServer
	[long]$Id
	[string]$Name
	[string]$OrgKey
	[string]$PriorityLevel
	[int]$Position
	[switch]$IsSystem
	[string]$Description
	[long]$AutoDeregisterInactiveVdiIntervalMs
	[long]$AutoDeleteKnownBadHashesDelay
	[hashtable]$AvSettings
	[hashtable[]]$Rules
	[long]$AutoDeregisterInactiveVmWorkloadsIntervalMs
	[hashtable[]]$DirectoryActionRules
	[string[]]$RapidConfigs
	[hashtable[]]$RuleConfigs
	[hashtable[]]$SensorConfigs
	[hashtable[]]$SensorSettings
	[string]$UpdateTime
}

class CBAnalyticsAlert{
	[CBCServer]$CBCServer
	[string]$Category
	[string]$CreateTime
	[int]$DeviceId
	[string]$DeviceName
	[string]$DeviceOs
	[string]$DeviceOsVersion
	[string]$DeviceUsername
	[string]$FirstEventTime
	[hashtable]$GroupDetails
	[string]$Id
	[string]$LastEventTime
	[string]$LastUpdateTime
	[string]$LegacyAlertId
	[switch]$NotesPresent
	[string]$OrgKey
	[string]$PolicyId
	[string]$PolicyName
	[int]$Severity
	[string[]]$Tags
	[string]$TargetValue
	[string]$ThreatId
	[string]$Type
	[pscustomobject]$Workflow
	[string]$BlockedThreatCategory
	[string]$CreatedByEventId
	[string]$DeviceLocation
	[string[]]$KillChainStatus
	[string]$NotBlockedThreatCategory
	[string]$PolicyApplied
	[string]$ProcessName
	[string]$Reason
	[string]$ReasonCode
	[string]$RunState
	[string]$SensorAction
	[string]$ThreatActivityC2
	[string]$ThreatActivityDlp
	[string]$ThreatActivityPhish
	[string]$ThreatCauseActorName
	[string]$ThreatCauseActorProcessPid
	[string]$ThreatCauseActorSha256
	[string]$ThreatCauseCauseEventId
	[string]$ThreatCauseReputation
	[string]$ThreatCauseThreatCategory
	[string]$ThreatCauseVector
	[pscustomobject]$ThreatIndicators
	# Not Documented
	[string]$AlertClassification
	[string]$ThreatCauseParentGuid
	[string]$ThreatCauseProcessGuid

}

class DeviceControlAlert{
	[CBCServer]$CBCServer
	[string]$Category
	[string]$CreateTime
	[int]$DeviceId
	[string]$DeviceName
	[string]$DeviceOs
	[string]$DeviceOsVersion
	[string]$DeviceUsername
	[string]$FirstEventTime
	[hashtable]$GroupDetails
	[string]$Id
	[string]$LastEventTime
	[string]$LastUpdateTime
	[string]$LegacyAlertId
	[switch]$NotesPresent
	[string]$OrgKey
	[string]$PolicyId
	[string]$PolicyName
	[int]$Severity
	[string[]]$Tags
	[string]$TargetValue
	[string]$ThreatId
	[string]$Type
	[pscustomobject]$Workflow
	[string]$DeviceLocation
	[string]$ExternalDeviceFriendlyName
	[string]$PolicyApplied
	[string]$ProductId
	[string]$ProductName
	[string]$Reason
	[string]$ReasonCode
	[string]$RunState
	[string]$SensorAction
	[string]$SerialNumber
	[string]$ThreatCauseCauseEventId
	[string]$ThreatCauseThreatCategory
	[string]$ThreatCauseVector
	[string]$VendorName
	[string]$VendorId
}

class WatchlistAlert{
	[CBCServer]$CBCServer
	[string]$Category
	[string]$CreateTime
	[int]$DeviceId
	[string]$DeviceName
	[string]$DeviceOs
	[string]$DeviceOsVersion
	[string]$DeviceUsername
	[string]$FirstEventTime
	[hashtable]$GroupDetails
	[string]$Id
	[string]$LastEventTime
	[string]$LastUpdateTime
	[string]$LegacyAlertId
	[switch]$NotesPresent
	[string]$OrgKey
	[string]$PolicyId
	[string]$PolicyName
	[int]$Severity
	[string[]]$Tags
	[string]$TargetValue
	[string]$ThreatId
	[string]$Type
	[pscustomobject]$Workflow
	[string]$IocField
	[string]$IocHit
	[string]$IocId
	[string]$ProcessGuid
	[string]$ProcessName
	[string]$Reason
	[string]$ReportId
	[string]$ReportName
	[string]$RunState
	[string]$ThreatCauseActorMd5
	[string]$ThreatCauseActorName
	[string]$ThreatCauseActorSha256
	[string]$ThreatCauseReputation
	[string]$ThreatCauseThreatCategory
	[string]$ThreatCauseVector
	[pscustomobject]$ThreatIndicators
	[pscustomobject]$Watchlists
	# Not documented
	[string]$AlertClassification
	[int]$Count
	[string]$DocumentGuid
}

class ContainerRuntimeAlert{
	[CBCServer]$CBCServer
	[string]$Category
	[string]$CreateTime
	[int]$DeviceId
	[string]$DeviceName
	[string]$DeviceOs
	[string]$DeviceOsVersion
	[string]$DeviceUsername
	[string]$FirstEventTime
	[hashtable]$GroupDetails
	[string]$Id
	[string]$LastEventTime
	[string]$LastUpdateTime
	[string]$LegacyAlertId
	[switch]$NotesPresent
	[string]$OrgKey
	[string]$PolicyId
	[string]$PolicyName
	[int]$Severity
	[string[]]$Tags
	[string]$TargetValue
	[string]$ThreatId
	[string]$Type
	[pscustomobject]$Workflow
	[string]$ClusterName
	[enum]$ConnectionType
	[string]$EgressGroupId
	[string]$EgressGroupName
	[int]$IpReputation
	[string]$Namespace
	[int]$Port
	[string]$Protocol
	[string]$RemoteDomain
	[string]$RemoteIp
	[switch]$RemoteIsPrivate
	[string]$RemoteNamespace
	[string]$RemoteReplicaId
	[string]$RemoteWorkloadId
	[string]$RemoteWorkloadKind
	[string]$RemoteWorkloadName
	[string]$ReplicaId
	[string]$RuleId
	[string]$RuleName
	[string]$WorkloadId
	[string]$WorkloadKind
	[string]$WorkloadName
}
