function ConvertTo-HashTable
{
    Param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $Object
    )
    $ObjectHash = @{}
    ($Object | Get-Member -Type NoteProperty).Name | ForEach-Object {
        if ($Object.$_ -is [PSCustomObject]) {
            $ObjectHash[(ConvertTo-PascalCase $_)] = (ConvertTo-HashTable $Object.$_)
        }
        else {
            $ObjectHash[(ConvertTo-PascalCase $_)] =  $Object.$_
        }
    }
    $ObjectHash
}
