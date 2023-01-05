Get-ChildItem -Path .\src\* -Include *.ps1,*.psm1 -Recurse | Edit-DTWBeautifyScript
Get-ChildItem -Path .\Tests\* -Include *.ps1,*.psm1 -Recurse | Edit-DTWBeautifyScript