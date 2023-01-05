$Paths = '.\src\*', '.\Tests\*'
Get-ChildItem -Path $Paths -Include *.ps1,*.psm1 -Recurse | Edit-DTWBeautifyScript -IndentType Tabs