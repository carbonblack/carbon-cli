$dotSourceParams = @{
    Filter      = '*.ps1'
    Recurse     = $true
    ErrorAction = 'Stop'
}

Try {
    $public = @(Get-ChildItem -Path "$PSScriptRoot\Public" @dotSourceParams)
    $private = @(Get-ChildItem -Path "$PSScriptRoot\Private" @dotSourceParams)
}
Catch {
    Throw $_
}

ForEach ($file in @($public + $private)) {
    Try {
        . $file.FullName
    }
    Catch {
        throw "Unable to dot source [$($file.FullName)]"
    }
}

Export-ModuleMember -Function $public.Basename