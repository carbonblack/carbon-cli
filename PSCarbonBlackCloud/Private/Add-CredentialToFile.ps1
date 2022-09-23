function Add-CredentialToFile {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] ${Server},

        [Parameter(Mandatory = $true)]
        [string] ${Org},

        [Parameter(Mandatory = $true)]
        [string] ${Token}
    )
    Process {
        $CredsTable = @{
            server = $Server;
            org    = $Org;
            token  = $Token;
        }
        $CredsPathUnix  = "${Home}/.carbonblack/PSCredentials.json"

        if ($IsLinux -Or $IsMacOS) {
            if (Test-Path -Path $CredsPathUnix -PathType Leaf) {
                $CredsFileTable = (Get-Content $CredsPathUnix | ConvertFrom-Json -AsHashtable)
                # TODO: Find a better way to add Hashtable to the Array
                $CredsFileTable += ($CredsTable | ConvertTo-Json)
                (ConvertTo-Json $CredsFileTable) > $CredsFile
            }
            else {
                $CredsFile = New-Item -Path $Home/.carbonblack/PSCredentials.json
                $CredsArray = @()
                $CredsArray += ($CredsTable | ConvertTo-Json)
                (ConvertTo-Json $CredsArray) > $CredsFile
            }
        }
        else {
            # Windows stuff
        }   
    }
}