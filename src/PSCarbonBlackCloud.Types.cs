using System;
using System.Collections.Generic;


namespace PSCarbonBlackCloud
{

    public static class DeploymentType
    {
        public static readonly string ENDPOINT = "ENDPOINT";
        public static readonly string WORKLOAD = "WORKLOAD";
        public static readonly string VDI = "VDI";
        public static readonly string AWS = "AWS";
    }

    public static class OS
    {
        public static readonly string WINDOWS = "WINDOWS";
        public static readonly string CENTOS = "CENTOS";
        public static readonly string RHEL = "RHEL";
        public static readonly string ORACLE = "ORACLE";
        public static readonly string SLES = "SLES";
        public static readonly string AMAZON_LINUX = "AMAZON_LINUX";
        public static readonly string SUSE = "SUSE";
        public static readonly string UBUNTU = "UBUNTU";
    }

    public static class SignatureStatus
    {
        public static readonly string NOT_APPLICABLE = "NOT_APPLICABLE";
        public static readonly string NOT_AVAILABLE = "NOT_AVAILABLE";
        public static readonly string UP_TO_DATE = "UP_TO_DATE";
        public static readonly string OUT_OF_DATE = "OUT_OF_DATE";
    }

    public static class Status
    {
        public static readonly string PENDING = "PENDING";
        public static readonly string REGISTERED = "REGISTERED";
        public static readonly string UNINSTALLED = "UNINSTALLED";
        public static readonly string DEREGISTERED = "DEREGISTERED";
        public static readonly string ACTIVE = "ACTIVE";
        public static readonly string INACTIVE = "INACTIVE";
        public static readonly string ERROR = "ERROR";
        public static readonly string ALL = "ALL";
        public static readonly string BYPASS_ON = "BYPASS_ON";
        public static readonly string BYPASS = "BYPASS";
        public static readonly string QUARANTINE = "QUARANTINE";
        public static readonly string SENSOR_OUTOFDATE = "SENSOR_OUTOFDATE";
        public static readonly string DELETED = "DELETED";
        public static readonly string LIVE = "LIVE";
    }

    public static class SubDeploymentType
    {
        public static readonly string VMWARE_VIRTUAL_MACHINE = "VMWARE_VIRTUAL_MACHINE";
        public static readonly string AWS_VIRTUAL_MACHINE_EC2 = "AWS_VIRTUAL_MACHINE_EC2";
    }

    public static class VirtualizationProvider
    {
        public static readonly string VMW_ESX = "VMW_ESX";
        public static readonly string VMW_WS = "VMW_WS";
        public static readonly string VMW_OTHER = "VMW_OTHER";
        public static readonly string HyperV = "HyperV";
        public static readonly string VirtualBox = "VirtualBox";
        public static readonly string AWS_EC2 = "AWS_EC2";
        public static readonly string OTHER = "OTHER";
    }

    public static class SensorStates
    {
        public static readonly string Active = "ACTIVE";
        public static readonly string PanicsDetected = "PANICS_DETECTED";
        public static readonly string LoopDetected = "LOOP_DETECTED";
        public static readonly string DbCorruptionDetected = "DB_CORRUPTION_DETECTED";
        public static readonly string CsrAction = "CSR_ACTION";
        public static readonly string RepuxAction = "REPUX_ACTION";
        public static readonly string DriverInitError = "DRIVER_INIT_ERROR";
        public static readonly string RemgrInitError = "REMGR_INIT_ERROR";
        public static readonly string UnsupportedOs = "UNSUPPORTED_OS";
        public static readonly string SensorUpgradeInProgress = "SENSOR_UPGRADE_IN_PROGRESS";
        public static readonly string SensorUnregistered = "SENSOR_UNREGISTERED";
        public static readonly string Watchdog = "WATCHDOG";
        public static readonly string SensorResetInProgress = "SENSOR_RESET_IN_PROGRESS";
        public static readonly string DriverInitRebootRequired = "DRIVER_INIT_REBOOT_REQUIRED";
        public static readonly string DriverLoadNotGranted = "DRIVER_LOAD_NOT_GRANTED";
        public static readonly string SensorShutdown = "SENSOR_SHUTDOWN";
        public static readonly string SensorMaintenance = "SENSOR_MAINTENANCE";
        public static readonly string FullDiskAccessNotGranted = "FULL_DISK_ACCESS_NOT_GRANTED";
        public static readonly string DebugModeEnabled = "DEBUG_MODE_ENABLED";
        public static readonly string AutoUpdateDisabled = "AUTO_UPDATE_DISABLED";
        public static readonly string SelfProtectDisabled = "SELF_PROTECT_DISABLED";
        public static readonly string VdiModeEnabled = "VDI_MODE_ENABLED";
        public static readonly string PocModeEnabled = "POC_MODE_ENABLED";
        public static readonly string SecurityCenterOptlnDisabled = "SECURITY_CENTER_OPTLN_DISABLED";
        public static readonly string LiveResponseRunning = "LIVE_RESPONSE_RUNNING";
        public static readonly string LiveResponseNotRunning = "LIVE_RESPONSE_NOT_RUNNING";
        public static readonly string LiveResponseKilled = "LIVE_RESPONSE_KILLED";
        public static readonly string LiveResponseNotKilled = "LIVE_RESPONSE_NOT_KILLED";
        public static readonly string LiveResponseEnabled = "LIVE_RESPONSE_ENABLED";
        public static readonly string LiveResponseDisabled = "LIVE_RESPONSE_DISABLED";
        public static readonly string DriverKernel = "DRIVER_KERNEL";
        public static readonly string DriverUserspace = "DRIVER_USERSPACE";
        public static readonly string DriverLoadPending = "DRIVER_LOAD_PENDING";
        public static readonly string OsVersionMismatch = "OS_VERSION_MISMATCH";
    }

    public static class AVStatus
    {
        public static readonly string AvNotRegistered = "AV_NOT_REGISTERED";
        public static readonly string AvRegistered = "AV_REGISTERED";
        public static readonly string AvDeregisteredAvDeregistered;
        public static readonly string AvActive = "AV_ACTIVE"; 
        public static readonly string AvBypass = "AV_BYPASS"; 
        public static readonly string SignatureUpdateDisabled = "SIGNATURE_UPDATE_DISABLED"; 
        public static readonly string OnaccessScanDisabled = "ONACCESS_SCAN_DISABLED"; 
        public static readonly string OndemandScanDisabled = "ONDEMAND_SCAN_DISABLED"; 
        public static readonly string ProductUpdateDisabled = "PRODUCT_UPDATE_DISABLED";
    }
    
    public class Server
    {
        public string Uri { get; set; }
        public string Org { get; set; }
        public string Token { get; set; }

        public override string ToString() 
        {
            return "[" + Org + "] " + Uri;
        }
    }

    public class Device
    {

        public string CurrentSensorPolicyName { get; set; }
        public string DeploymentType { get; set; }

        // TODO: This contains a list and should be changed
        public string DeviceMetaDataItemList { get; set;}

        public string Id { get; set; }
        public string LastContactTime { get; set; }
        public string LastDevicePolicyChangedTime { get; set; }
        public string LastDevicePolicyRequestedTime { get; set; }
        public string LastExternalIpAddress { get; set; }
        public string LastInternalIpAddress { get; set; }
        public string LastLocation { get; set; }
        public string LastPolicyUpdatedTime { get; set; }
        public string LastReportedTime { get; set; }
        public string LastResetTime { get; set; }
        public string LastShutdownTime { get; set; }
        public string LoginUserName { get; set; }
        public string MacAddress { get; set; }
        public string Name { get; set; }
        public string OrganizationId { get; set; }
        public string OrganizationName { get; set; }
        public string Os { get; set; }
        public string OsVersion { get; set; }
        public bool PassiveMode { get; set; }
        public int PolicyId { get; set; }
        public string PolicyName { get; set; }
        public bool Quarantined { get; set; }
        public string ScanLastActionTime { get; set; }
        public string SensorKitType { get; set; }
        public bool SensorOutOfDate { get; set; }
        public bool SensorPendingUpdate { get; set; }
        public string SensorStates { get; set; }
        public string SensorVersion { get; set; }
        public string Status { get; set; }
        public string TargetPriority { get; set; }
        public string VdiBaseDevice { get; set; }
        public int AdGroupId { get; set; }
        public bool PolicyOverride { get; set; }
        public string ActivationCode { get; set; }
        public string ActivationCodeExpiryTime { get; set; }
        public string DeregisteredTime { get; set; }
        public int DeviceOwnerId { get; set; }
        public string Email { get; set; }
        public string FirstName { get; set; }
        public string MiddleName { get; set; }
        public string EncodedActivationCode { get; set; }
        public string LastName { get; set; }
        public string RegisteredTime { get; set; }
        public string UninstallCode { get; set; }
        public string AvAveVersion { get; set; }
        public string AvEngine { get; set; }
        public string AvLastScanTime { get; set; }
        public bool AvMaster { get; set; }
        public string AvPackVersion { get; set; }
        public string AvProductVersion { get; set; }
        public string AvStatus { get; set; }

        // TODO: This contains a list and should be changed
        public int AvUpdateServers { get; set; }
    
        public string ApplianceName { get; set; }
        public string ApplianceUuid { get; set; }
        public string ClusterName { get; set; }
        public string DatacenterName { get; set; }
        public string EsxHostName { get; set; }
        public string EsxHostUuid { get; set; }
        public bool GoldenDevice { get; set; }
        public int GoldenDeviceId { get; set; }
        public string NsxDistributedFirewallPolicy { get; set; }
        public bool NsxEnabled { get; set; }
        public string VcenterHostUrl { get; set; }
        public string VcenterName { get; set; }
        public string VcenterUuid { get; set; }
        public bool VirtualMachine { get; set; }
        public string VirtualPrivateCloudId { get; set; }
        public string VirtualizationProvider { get; set; }
        public string VmIp { get; set; }
        public string VmName { get; set; }
        public string VmUuid { get; set; }
        public long VulnerabilityScore { get; set; }
        public string VulnerabilitySeverity { get; set; }
        public long AutoScalingGroupName { get; set; }
        public long CloudProviderAccountId { get; set; }
        public long CloudProviderResourceId { get; set; }
        public string[] CloudProviderTags { get; set; }

        public string HostBasedFirewallFailureReason { get; set; }
        public string HostBasedFirewallReasons { get; set; }
        public string HostBasedFirewallStatus { get; set; }
        public string BaseDevice { get; set; }
        public string AvVdfVersion { get; set; }
        public string LinuxKernelVersion { get; set; }
        public string ScanLastCompleteTime { get; set; }
        public string ScanStatus { get; set; }
        public string WindowsPlatform { get; set; }
        public string VdiProvider { get; set; }
        public string InfrastructureProvider { get; set; }
        public string SensorGatewayUrl { get; set; }
        public string SensorGatewayUuid { get; set; }
    }

     public class Policy
    {
        public long Id { get; set; }
        public bool IsSystem { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string PriorityLevel { get; set; }
        public long Position { get; set; }
        public long NumDevices { get; set; } 
    }
}