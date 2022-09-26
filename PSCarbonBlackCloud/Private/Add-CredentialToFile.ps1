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
        $CredsTable = [PSCustomObject]@{
            server = $Server;
            org    = $Org;
            token  = $Token;
        }
        $CredsPathUnix  = "${Home}/.carbonblack/PSCredentials.json"

        if ($IsLinux -Or $IsMacOS) {
            if (Test-Path -Path $CredsPathUnix -PathType Leaf) {
                $CredsFileTable = (Get-Content $CredsPathUnix | ConvertFrom-Json -NoEnumerate)
                $CredsFileTable += $CredsTable
                (ConvertTo-Json $CredsFileTable) > $CredsPathUnix
            }
            else {
                $CredsFile = New-Item -Path $CredsPathUnix
                $CredsArray = @()
                $CredsArray += ($CredsTable)
                (ConvertTo-Json $CredsArray) > $CredsFile
            }
        }
        else {
            # Windows stuff
        }   
    }
}