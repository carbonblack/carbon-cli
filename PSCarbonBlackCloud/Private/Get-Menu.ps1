function Get-Menu {
    if ($IsLinux -Or $IsMacOS) {
        Set-Variable CBCCredentialsUNIXPath -Option ReadOnly -Value "${Home}/.carbonblack/PSCredentials.json"
        if (Test-Path -Path $CBCCredentialsUNIXPath -PathType Leaf) {
            $Credentials = (Get-Content $CBCCredentialsUNIXPath | ConvertFrom-Json -NoEnumerate)
            $credCount = 1
            Write-Host "Select a server from the list (by typing its number and pressing Enter):"
            $hash = @{}
            foreach ( $cred in $Credentials ) {
                $hashtable = $cred | ConvertTo-Json | ConvertFrom-Json -AsHashTable
                $hash[$credCount] = $hashtable["server"]    
                $credCount += 1
            }
            for ($index = 1; $index -lt $credCount; $index++) {
                Write-Host "[$index]: $($hash[$index])"
            }
            $number = Read-Host
            if ($hash.Keys -contains $number) {
                $credentialHash = $Credentials[$number - 1] | ConvertTo-Json | ConvertFrom-Json -AsHashtable
                return $credentialHash
            }
            else {
                Write-Host "There is no server with that number"
            }
        }
        else {
            Write-Host "The Credential File is empty"
        }
    }
}