$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.Run.Path = ".\Tests\*"
$config.Output.Verbosity = "Detailed"
$config.TestResult.Enabled = $true 
$config.Run.Exit = $true

Invoke-Pester -Configuration $config -WarningAction Ignore
