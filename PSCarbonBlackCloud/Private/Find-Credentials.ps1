function Find-Credentials{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]${Server},

        [Parameter(Mandatory=$true)]
        [string]${Path}
    )
    
    if (Test-Path -Path $Path -PathType Leaf) {
        $Credentials = (Get-Content $Path | ConvertFrom-Json -NoEnumerate)
        foreach ( $cred in $Credentials ) {
            $hashtable = $cred | ConvertTo-Json | ConvertFrom-Json -AsHashTable
            if ($hashtable["server"] -eq $Server) {
                return $hashtable
            }
        }
        return @{}
    }
}