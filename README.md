# PSCarbonBlackCloud

[![Codeship Status for carbonblack/PSCarbonBlackCloud](https://app.codeship.com/projects/a2c8442f-fc13-4f81-9980-ad1413074d3d/status?branch=main)](https://app.codeship.com/projects/462505)

A set of PowerShell Cmdlets to interact with Carbon Black Cloud.

## Getting Started

```powershell
PS > git clone https://github.com/carbonblack/PSCarbonBlackCloud.git
PS > cd ./PSCarbonBlackCloud
PS > Import-Module ./src/PSCarbonBlackCloud.psm1
```

Now we can start using the cmdlets.


```powershell
PS > Connect-CbcServer -CbcServer "http://cbcserver.cbc" -Org "MyOrg" -Token "MyToken"
```

## Development

Build the project:

```powershell
PS > ./Build-PSCarbonBlackCloud.ps1
```

Install `pre-commit`

macOS:

```bash
$ brew install pre-commit
$ pre-commit install
```

Using pip:

```bash
$ pip install pre-commit
$ pre-commit install
```

### Run Tests

```powershell
PS > ./Invoke-Tests.ps1
```

If you want to check the test coverage for all of the files

```powershell
Invoke-Pester -CodeCoverage ./src/Public/*
```

or for specific file:

```powershell
Invoke-Pester -CodeCoverage ./src/Public/Get-CbcDevice.ps1
```

If you want to enable debug information

```powershell
$DebugPreference = 'Continue'
```

### Using VSCode and Pester

Please refer to this documentation: https://pester.dev/docs/usage/vscode
