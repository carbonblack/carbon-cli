Import-Module ./src/PSCarbonBlackCloud.psd1 
# $DebugPreference = 'Continue'
# Set-PsDebug -Trace 2

# List all available cmdlets 
Get-Command -Module PSCarbonBlackCloud  

# Count the number of Carbon Black Cloud cmdlets
Get-Command -Module PSCarbonBlackCloud | Measure-Object | Select Count

# Establish a connection to a Carbon Black Cloud Endpoint
# Create a PSCredential object. Specify OrgId as a value for User and Token as a value for password when prompted.
$myCredentials = Get-Credential
$cbcServerOrg1 = Connect-CBCServer -Server https://defense.conferdeploy.net/ -Credential $myCredentials -Notes Org1


# Design principle on focus: Each cmdlet is documented as part of its codebase. Learn Carbon Black leveraging Get-Help cmdlet
Get-Help Connect-CbcServer -Full

# Retrieve devices, alerts, etc.
Get-Help Get-CbcDevice -Full
Get-CbcDevice

Get-Help Get-CbcAlert -Full
Get-CbcAlert

# Design principle on focus: In Powershell everything is an object. Carbon Black CLI has its own object model that losely mimics the underlying API model.
Get-CbcDevice | Get-Member
Get-CbcProcess | Get-Member

# Design principle on focus: There is a separation between the object model definition and the object presentation layer. Review Format.ps1xml !
Get-CbcDevice | Select-Object Id, Server, LastShutdownTime

# Design principle on focus: Working against multiple connections. Each connection is defined uniquely by a URI/Org pair. 
$cbcServerOrg2 = Connect-CBCServer -Server https://defense.conferdeploy.net/ -Org ABCD1234 -Token ABCDEFGHIJKLMNO123456789/ABCD123456 -Notes Org2


# Retrieve alerts, devices from multiple connections.
Get-CbcAlerts
Get-CbcDevice
Get-CbcDevice | Select-Object Id, Server, SensorVersion

# Retrieve the Org1 devices only 
Get-CbcDevice -Server $cbcServerOrg1

# Create a simple HTML report on LOW priority "Windows 10" devices
Get-CbcDevice -OS Windows -OSVersion "Windows 10 x64" -TargetPriority LOW | ConvertTo-Html | Out-File DeviceReport.html

# Server-side filtering using cmdlet filter params
Get-CbcDevice -OS Windows
Get-CbcDevice -OS Windows -OSVersion "Windows 10 x64"
Get-CbcDevice -OS Windows -OSVersion "Windows 10 x64" -TargetPriority LOW

# Client-side filtering. No filter param for sensor version
Get-CbcDevice | Where-Object {$_.SensorVersion -like "windows:3.9*"}

# Beyond reporting: Creating and manipulating objects in your CBC environment
Get-CbcDevice -OS Windows -OSVersion "Windows 10 x64" -TargetPriority LOW | Set-CbcDevice -QuarantineEnabled $true
Get-CbcDevice -OS Windows -OSVersion "Windows 10 x64" -TargetPriority LOW | Set-CbcDevice -QuarantineEnabled $false
Get-Help Set-CbcDevice -Full

# Get policies and update device policy
Get-CbcDevice
Get-CbcPolicy
Set-CbcDevice -Id 123456789 -PolicyId 12345

# Working with long running operations ( process search / observations search )
Get-CbcDevice 
Get-CbcProcess -DeviceId 123456789
Get-CbcProcess -Query "process_name:power*" 
$processSearchJob = Get-CbcProcess -Query "process_name:power*" -AsJob
Get-CbcJob $processSearchJob
Receive-CbcJob $processSearchJob

# Observations 
Get-Help Get-CbcObservation -Full
Get-CbcObservation -EventType "netconn"
Get-CbcObservation -Query "event_type:netconn"

# Get observations for alert
Get-CbcAlert -Id "c295b8fc-0f5d-7193-3075-0301862c69b7" | Get-CbcObservation

# Create feed, report, ioc and then subscribe for that feed (create a watchlist)
# Create empty feed
$feed = New-CbcFeed -Name mydemo -ProviderUrl http://test.test/ -Summary summary -Category demo -Alertable $true

# Create empty report and add it to the feeed
$report = New-CbcReport -Feed $feed -Title myreport -Description description -Severity 5

# Create one IOC and add it to the created report
$Body = @{"match_type" = "equality"
"field" =  "process_name"
"values" = @("googleupdate.exe")}
New-CbcIoc -Report $report -Body $Body

# Subscribe to that feed
New-CbcWatchlist -Feed $feed
