using module ../PSCarbonBlackCloud.Classes.psm1

<#
.SYNOPSIS
This cmdlet establishes a connection to the Cbc Server
.DESCRIPTION
This cmdlet establishes a connection to the Cbc Server
Takes `-Server, -Org, -Token` parameters.
.PARAMETER CbcServer
Specifies the IP or HTTP addresses of the Cbc Server you want to connect to.
.PARAMETER Token
Specifies the Token that is going to be used in the authentication process.
.PARAMETER Org
Specifies the Organization that is going to be used in the authentication process.
.PARAMETER SaveCredentials
Indicates that you want to save the specified credentials in the local credential store.
.PARAMETER Menu
Connects to a Cbc Server from the list of recently connected servers.
.OUTPUTS
CbcServer
.EXAMPLE
PS > Connect-CbcServer -CbcServer "http://cbcserver.cbc" -Org "MyOrg" -Token "MyToken"

Connects with the specified Server, Org, Token and returns a CbcServer Object.
.EXAMPLE
PS > Connect-CbcServer -CbcServer "http://cbcserver1.cbc" -Org "MyOrg1" -Token "MyToken1" -SaveCredential

Connect with the specified Server, Org, Token, returns a CbcServer Object and saves
the credentials in the Credential file.
.EXAMPLE
PS > Connect-CbcServer -Menu

It prints the available Cbc Servers from the Credential file so that the user can choose with which
one to connect.
.LINK
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud
#>
function Connect-CbcServer {
	[CmdletBinding(DefaultParameterSetName = "default",HelpUri = "http://devnetworketc/")]
	param(
		[Parameter(ParameterSetName = "default",Mandatory = $true,Position = 0)]
		[Alias("Server")]
		[string]${Uri},

		[Parameter(ParameterSetName = "default",Mandatory = $true,Position = 1)]
		[string]${Org},

		[Parameter(ParameterSetName = "default",Mandatory = $true,Position = 2)]
		[string]${Token},

		[Parameter(ParameterSetName = "default")]
		[switch]${SaveCredentials},

		[Parameter(ParameterSetName = "menu")]
		[switch]$Menu
	)

	begin {
		Write-Debug "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {

		# Show the currently connected Cbc servers warning
		if ($global:CBC_CONFIG.currentConnections.Count -ge 1) {

			# Check if you are already connected to this server
			$global:CBC_CONFIG.currentConnections | ForEach-Object {
				if (($_.Uri -eq $Uri) -and ($_.Org -eq $Org)) {
					Write-Error 'You are already connected to this server!' -ErrorAction 'Stop'
				}
			}

			Write-Warning -Message "You are currently connected to: "
			$global:CBC_CONFIG.currentConnections | ForEach-Object {
				$Index = $global:CBC_CONFIG.currentConnections.IndexOf($_) + 1
				$OutputMessage = "[${Index}] " + $_.Uri + " Organization: " + $_.Org
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

				$CbcServerObject = [CbcServer]::new($Uri,$Org,$Token)
				if ($SaveCredentials.IsPresent) {
					if ($global:CBC_CONFIG.credentials.IsInFile($CbcServerObject)) {
						Write-Error "The credentials are already saved!" -ErrorAction "Stop"
					} else {
						$global:CBC_CONFIG.defaultServers.Add($CbcServerObject) | Out-Null
						$global:CBC_CONFIG.credentials.SaveToFile($CbcServerObject)
					}
				}
			}
			"menu" {
				Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing (menu)"

				if ($global:CBC_CONFIG.defaultServers.Count -eq 0) {
					Write-Error "There are no default servers avaliable!" -ErrorAction "Stop"
				}
				$global:CBC_CONFIG.defaultServers | ForEach-Object {
					$Index = $global:CBC_CONFIG.defaultServers.IndexOf($_) + 1
					$OutputMessage = "[${Index}] " + $_.Uri + " Organization: " + $_.Org
					Write-Output $OutputMessage
				}
				$OptionInput = { (Read-Host) -as [int] }
				$Option = & $OptionInput
				if (($Option -gt $global:CBC_CONFIG.defaultServers.Count) -or ($Option -lt 0)) {
					Write-Error "There is no default server with that index" -ErrorAction "Stop"
				}
				$CbcServerObject = [CbcServer]::new(
					$global:CBC_CONFIG.defaultServers[$Option - 1].Uri,
					$global:CBC_CONFIG.defaultServers[$Option - 1].Org,
					$global:CBC_CONFIG.defaultServers[$Option - 1].Token
				)
			}
		}

		if ($CbcServerObject.IsConnected()) {
			Write-Error "You are already connected to this server and organization!" -ErrorAction Stop
		}

		$TestConnection = Invoke-CBCRequest -Server $CbcServerObject -Endpoint "/" -Method Get
		if ($TestConnection.StatusCode -ne 200) {
			Write-Error "Cannot connect to the server" -ErrorAction Stop
		}

		$global:CBC_CONFIG.currentConnections.Add($CbcServerObject) | Out-Null
		return $CbcServerObject

		end {
			Write-Debug "[$($MyInvocation.MyCommand.Name)] function finished"
		}
	}
}
