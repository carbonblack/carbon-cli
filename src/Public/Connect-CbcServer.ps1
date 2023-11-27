using module ../PSCarbonBlackCloud.Classes.psm1

<#
.SYNOPSIS
This cmdlet establishes a connection to the specified CBC Sever endpoint and corresponding organization
.DESCRIPTION
Establish a connection to a CBC Sever endpoint and corresponding organization by providing arguments for hte  
`-Server, -Org and -Token` parameters. To disconnect from a server, you can use the Disconnect-CbcServer cmdlet. 
CarbonCLI supports working with multiple default connections. Unique connections are determined from the Uri/Org pair. Multiple connections to the same 
Uri/Org are not allowed (even with different tokens). Every time when you establish a different connection by using the Connect-CbcServer cmdlet, 
the new connection is stored in a global array variable together with the previously established connections. This variable is named $DefaultCbcServers and its initial value is an empty array. 
When you run a cmdlet and the target servers cannot be determined from the context of the specified parameters or the -Server parameter itself, 
the cmdlet runs against all connections stored in the $DefaultCbcServers array variable. Disconnect-CbcServer does remove the coresponding server from $DefaultCbcServers. 
You could also manipulate the $DefaultCbcServers array manually. 

.PARAMETER Uri
Specifies the IP or HTTP addresses of the Cbc Server you want to connect to.
.PARAMETER Org
Specifies the Organization that is going to be used in the authentication process.
.PARAMETER Token
Specifies the X-Auth token that is going to be used in the authentication process.
.PARAMETER SaveConnection
Indicates that you want to save the specified connection in the local connection store. 
This includes storing Uri, Org and Token. Saved connections can be used with Connect-CbcServer -Menu option.
On Windows machines the Token is stored as an encrypted string using the Windows Data Protection API for encryption. 
This effectively means that only the same user account on the same computer will be able to use this encrypted string.
NB: On the rest of the platforms the token is not encrypted rather than obduscated. 
.PARAMETER Menu
Switch parameter. Lists all available connections from the local connection store.
.PARAMETER Credential
You could provide atuhentication details such as Org Id and the X-AUTH token as a PSCredential object. 
The Org Id should be provided to the PSCredential.UserName property and the X-AUTH token to the PSCredentail.Password property.
In case a string is provided for an argument of the Credential parameter it will be treated as an Org Id and you will be prompted for the corresponding token. 
See the provided examples. 

.OUTPUTS
CbcServer
.EXAMPLE
PS > Connect-CbcServer -Server "http://cbcserver.cbc" -Org "MyOrg" -Token "MyToken" -Notes "ProdEnv"

Connects with the specified Server, Org, Token and returns a CbcServer Object. 

.EXAMPLE
PS > Connect-CbcServer -Server "http://cbcserver.cbc" -Org "MyOrg" -Token "MyToken" -Notes "ProdEnv" -SaveConnection 

Store the connection in the local store for reuse across multiple Powershell sesssions. 

.EXAMPLE
PS > Connect-CbcServer -Menu

List all connections from the local connection store.

.EXAMPLE
PS > $cred = Get-Credential

PowerShell credential request
Enter your credentials.
User: MyOrg
Password for user MyOrg: ****

PS > Connect-CbcServer -Server "http://cbcserver.cbc" -Credential $cred

Connects with the specified Server, Org, Token and returns a CbcServer Object.

.EXAMPLE

PS > Connect-CbcServer -Server "http://cbcserver.cbc" -Credential "MyOrg"

PowerShell credential request
Enter your credentials.
Password for user MyOrg:

Connects with the specified Server, Org, Token and returns a CbcServer Object.

.EXAMPLE
PS > $prodServer = Connect-CbcServer -Server "http://prod.cbc" -Org "MyOrg1" -Token "MyProdToken" -Notes "ProdEnv"
PS > $devServer = Connect-CbcServer -Server "http://dev.cbc" -Org "MyOrg1" -Token "MyDevToken" -Notes "DevEnv"
Connects to the specified two environments.
PS > $DefaultCbcServers
List the two active connections.

PS > Get-CbcAlert
Retrieves all alerts from both the Prod and Dev environments.

PS > Get-CbcAlert -Server $prodServer
Retrieves only alerts from prod env. 

PS > $prodAlert234 = Get-CbcAlert -Id "2434" -Server $prodServer
PS > Set-CbcAlert -Alert $prodAlert234 -Dismiss
Retrieves a CBC Alert with id = 234 from the prod environment and then dismisses it.
Same as: 
PS > Get-CbcAlert -Id "2434" -Server $prodServer | Set-CbcAlert -Dismiss

.EXAMPLE
PS > $prodServer = Connect-CbcServer -Server "http://prod.cbc" -Org "MyOrg1" -Token "MyProdToken" -Notes "ProdEnv"
PS > $devServer = Connect-CbcServer -Server "http://dev.cbc" -Org "MyOrg1" -Token "MyDevToken" -Notes "DevEnv"
Connects to the specified two environments.
PS > $IncludeCriteria = @{}
PS > $IncludeCriteria.type = @("CB_ANALYTICS")
PS > $IncludeCriteria.minimum_severity = 3
PS > Get-CbcAlert -Include $IncludeCriteria -Server $prodServer | foreach { Set-CbcDevice -Id $_.DeviceID -QuarantineEnabled $true }
Retrieves all alerts with the specified criteria from the prod env and quarantines all devices ( on the prod env as infered from the Alerts objects passed throug the pipeline)
that contain that alert

.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud
#>
function Connect-CbcServer {
	[CmdletBinding(DefaultParameterSetName = "default")]
	param(
		
		[Parameter(ParameterSetName = "default", Mandatory = $true, Position = 0)]
		[Parameter(ParameterSetName = "credentials", Mandatory = $true)]
		[Alias("Server")]
		[string]$Uri,

		[Parameter(ParameterSetName = "default", Mandatory = $true, Position = 1)]
		[string]$Org,

		[Parameter(ParameterSetName = "default", Mandatory = $true, Position = 2)]
		[string]$Token, 

		[Parameter(ParameterSetName = "default", Position = 3)]
		[Parameter(ParameterSetName = "credentials")]
		[string]$Notes,

		[Parameter(ParameterSetName = "default")]
		[Parameter(ParameterSetName = "credentials")]
		[switch]$SaveConnection,

		[Parameter(ParameterSetName = "menu")]
		[switch]$Menu,

		[Parameter(ParameterSetName = "credentials", Mandatory = $true)]
		[System.Management.Automation.Credential()]
		[System.Management.Automation.PSCredential] $Credential
	)

	begin {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {

		# Show the currently connected Cbc servers warning
		if ($global:DefaultCbcServers.Count -ge 1) {
			
			Write-Warning -Message "You are currently connected to: "
			$global:DefaultCbcServers | ForEach-Object {
				$OutputMessage = $_.Uri + " Organization: " + $_.Org
				Write-Warning -Message $OutputMessage
			}
			Write-Warning -Message "If you wish to disconnect the currently connected Cbc servers, please use Disconnect-CbcServer cmdlet. If you wish to continue connecting to new servers press any key or `Q` to quit."
			$Option = Read-Host
			if ($Option.ToLower() -eq 'q') {
				Write-Error 'Exit' -ErrorAction 'Stop'
			}
		}

		# Creating the $CbcServerObject within the switch
		switch ($PSCmdlet.ParameterSetName) {
			"default" {
				Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing (default) [$Uri, $Org, $Token]"
				$secureStringToken  = $Token | ConvertTo-SecureString -AsPlainText
				$CbcServerObject = [CbcServer]::new($Uri, $Org, $secureStringToken, $Notes)
				if ($CbcServerObject.IsConnected($global:DefaultCbcServers)) {
					if ($PSBoundParameters.ContainsKey("Notes")) {
						Write-Warning 'You are already connected to this server and organization. Updating notes. No additional connection established.'
						$global:DefaultCbcServers | where {($_.URI -ieq $Uri) -and ($_.Org -ieq $Org)} | foreach {$_.Notes = $Notes}
					} else {
						Write-Error 'You are already connected to this server and organization. No additional connection established.' -ErrorAction 'Stop'
					}
				} else {
					$TestConnection = Invoke-CBCRequest -Server $CbcServerObject -Endpoint "/" -Method Get
					if ($TestConnection.StatusCode -ne 200) {
						Write-Error "Cannot connect to the server" -ErrorAction Stop
					}
					$global:DefaultCbcServers.Add($CbcServerObject) | Out-Null
					if ($SaveConnection.IsPresent) {
						if (($global:CBC_CONFIG.savedConnections.IsInFile($CbcServerObject)) -and $PSBoundParameters.ContainsKey("Notes")) {
							# UpdateNotes
							Write-Warning "Connection is already saved. Updating Notes for the saved connection."
							$global:CBC_CONFIG.sessionConnections | where {($_.URI -ieq $Uri) -and ($_.Org -ieq $Org)} | foreach {$_.Notes = $Notes}
						} elseif ($global:CBC_CONFIG.savedConnections.IsInFile($CbcServerObject)) {
							Write-Warning "The connection is already saved!. No updates to it."
						} else {
							$global:CBC_CONFIG.sessionConnections.Add($CbcServerObject) | Out-Null
							$global:CBC_CONFIG.savedConnections.SaveToFile($CbcServerObject)
						}
					}
				}
			}
			"credentials" {
				Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing (credentials)"
				
				$CbcServerObject = [CbcServer]::new($Uri, $Credential.UserName, $Credential.Password, $Notes)
				if ($CbcServerObject.IsConnected($global:DefaultCbcServers)) {
					if ($PSBoundParameters.ContainsKey("Notes")) {
						Write-Warning 'You are already connected to this server and organization. Updating notes. No additional connection established.'
						$global:DefaultCbcServers | where {($_.URI -ieq $Uri) -and ($_.Org -ieq $Org)} | foreach {$_.Notes = $Notes}
					} else {
						Write-Error 'You are already connected to this server and organization. No additional connection established.' -ErrorAction 'Stop'
					}
				} else {
					$TestConnection = Invoke-CBCRequest -Server $CbcServerObject -Endpoint "/" -Method Get
					if ($TestConnection.StatusCode -ne 200) {
						Write-Error "Cannot connect to the server" -ErrorAction Stop
					}
					$global:DefaultCbcServers.Add($CbcServerObject) | Out-Null
					if ($SaveConnection.IsPresent) {
						if (($global:CBC_CONFIG.savedConnections.IsInFile($CbcServerObject)) -and $PSBoundParameters.ContainsKey("Notes")) {
							# UpdateNotes
							Write-Warning "Connection is already saved. Updating Notes for the saved connection."
							$global:CBC_CONFIG.sessionConnections | where {($_.URI -ieq $Uri) -and ($_.Org -ieq $Org)} | foreach {$_.Notes = $Notes}
						} elseif ($global:CBC_CONFIG.savedConnections.IsInFile($CbcServerObject)) {
							Write-Warning "The connection is already saved!. No updates to it."
						} else {
							$global:CBC_CONFIG.sessionConnections.Add($CbcServerObject) | Out-Null
							$global:CBC_CONFIG.savedConnections.SaveToFile($CbcServerObject)
						}
					}
				}
			}
			"menu" {
				Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing (menu)"

				if ($global:CBC_CONFIG.sessionConnections.Count -eq 0) {
					Write-Error "There are no saved connections avaliable!" -ErrorAction "Stop"
				}
				$global:CBC_CONFIG.sessionConnections | ForEach-Object {
					$Index = $global:CBC_CONFIG.sessionConnections.IndexOf($_) + 1
					$OutputMessage = "[${Index}] " + $_.Uri + " Organization: " + $_.Org + " Notes: " + $_.Notes
					Write-Output $OutputMessage
				}
				$OptionInput = { (Read-Host) -as [int] }
				$Option = & $OptionInput
				if (($Option -gt $global:CBC_CONFIG.sessionConnections.Count) -or ($Option -lt 0)) {
					Write-Error "There is no available connection with that index" -ErrorAction "Stop"
				}
				$CbcServerObject = [CbcServer]::new(
					$global:CBC_CONFIG.sessionConnections[$Option - 1].Uri,
					$global:CBC_CONFIG.sessionConnections[$Option - 1].Org,
					$global:CBC_CONFIG.sessionConnections[$Option - 1].Token,
					$global:CBC_CONFIG.sessionConnections[$Option - 1].Notes
				)
				if ($CbcServerObject.IsConnected($global:DefaultCbcServers)) {
					Write-Error 'You are already connected to this server and organization. No additional connection established.' -ErrorAction 'Stop'
				} else {
					$TestConnection = Invoke-CBCRequest -Server $CbcServerObject -Endpoint "/" -Method Get
					if ($TestConnection.StatusCode -ne 200) {
						Write-Error "Cannot connect to the server" -ErrorAction Stop
					}
					$global:DefaultCbcServers.Add($CbcServerObject) | Out-Null
				}
			}
			
		}
		return $CbcServerObject
	}
	end {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
	}
}
