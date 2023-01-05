using module ../PSCarbonBlackCloud.Classes.psm1

<#
.DESCRIPTION
    This cmdlet establishes a connection to the CBC Server specified by the -CBCServer parameter.
.PARAMETER CBCServer
    Specifies the IP or HTTP addresses of the CBC Server you want to connect to.
.PARAMETER Token
    Specifies the Token that is going to be used in the authentication process.
.PARAMETER Org
    Specifies the Organization that is going to be used in the authentication process.
.PARAMETER SaveCredentials
    Indicates that you want to save the specified credentials in the local credential store.
.PARAMETER Menu
    Connects to a CBC Server from the list of recently connected servers.
.OUTPUTS
    A CBCServer Object
.NOTES
    -------------------------- EXAMPLE 1 --------------------------

    PS > Connect-CBCServer -CBCServer "http://cbcserver.cbc" -Org "MyOrg" -Token "MyToken"

    Connects with the specified Server, Org, Token and returns a CBCServer Object.



    -------------------------- EXAMPLE 2 --------------------------

    PS > Connect-CBCServer -CBCServer "http://cbcserver1.cbc" -Org "MyOrg1" -Token "MyToken1" -SaveCredential

    Connect with the specified Server, Org, Token, returns a CBCServer Object and saves 
    the credentials in the Credential file.



    -------------------------- EXAMPLE 3 --------------------------

    PS > Connect-CBCServer -Menu

    It prints the available CBC Servers from the Credential file so that the user can choose with which one to connect.



.LINK
API Documentation: http://devnetworketc/
#>
function Connect-CBCServer {
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
		Write-Verbose "[$($MyInvocation.MyCommand.Name)] function started"
	}

	process {

		# Show the currently connected CBC servers warning
		if ($global:CBC_CONFIG.currentConnections.Count -ge 1) {
			Write-Warning -Message "You are currently connected to: "
			$global:CBC_CONFIG.currentConnections | ForEach-Object {
				$Index = $global:CBC_CONFIG.currentConnections.IndexOf($_) + 1
				$OutputMessage = "[${Index}] " + $_.Uri + " Organization: " + $_.Org
				Write-Warning $OutputMessage
			}
			Write-Warning -Message 'If you wish to disconnect the currently connected CBC servers, please use Disconnect-CBCServer cmdlet. 
         If you wish to continue connecting to new servers press any key or `Q` to quit.'
			$Option = Read-Host
			if ($Option.ToLower() -eq 'q') {
				Write-Error 'Exit' -ErrorAction 'Stop'
			}
		}

		# Creating the $CBCServerObject within the switch
		switch ($PSCmdlet.ParameterSetName) {
			"default" {
				Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing (default) [$Uri, $Org, $Token]"

				$CBCServerObject = [CBCServer]::new($Uri,$Org,$Token)
				if ($SaveCredentials.IsPresent) {
					if ($global:CBC_CONFIG.credentials.IsInFile($CBCServerObject)) {
						Write-Error "The credentials are already saved!" -ErrorAction "Stop"
					} else {
						$global:CBC_CONFIG.defaultServers.Add($CBCServerObject) | Out-Null
						$global:CBC_CONFIG.credentials.SaveToFile($CBCServerObject)
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
				$CBCServerObject = [CBCServer]::new(
					$global:CBC_CONFIG.defaultServers[$Option - 1].Uri,
					$global:CBC_CONFIG.defaultServers[$Option - 1].Org,
					$global:CBC_CONFIG.defaultServers[$Option - 1].Token
				)
			}
		}

		if ($CBCServerObject.IsConnected()) {
			Write-Error "You are already connected to this server and organization!" -ErrorAction Stop
		}

		$global:CBC_CONFIG.currentConnections.Add($CBCServerObject) | Out-Null
		return $CBCServerObject

		end {
			Write-Verbose "[$($MyInvocation.MyCommand.Name)] function finished"
		}
	}
}
