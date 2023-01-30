# PSCarbonBlackCloud

[![Codeship Status for carbonblack/PSCarbonBlackCloud](https://app.codeship.com/projects/a2c8442f-fc13-4f81-9980-ad1413074d3d/status?branch=main)](https://app.codeship.com/projects/462505)

A set of PowerShell Cmdlets to interact with Carbon Black Cloud.

## Build the Project / Install Dependencies

```console
PS> ./Build-PSCarbonBlackCloud.ps1
```

Install `pre-commit`

macOS:

```
$ brew install pre-commit
$ pre-commit install
```

Using pip:

```
$ pip install pre-commit
$ pre-commit install
```

## Run Tests

```console
PS> ./Invoke-Tests.ps1
```

If you want to enable debug information

```powershell
$DebugPreference = 'Continue'
```

### Using VSCode and Pester

Please refer to this documentation: https://pester.dev/docs/usage/vscode

## Importing the Module

```console
PS> Import-Module ./src/PSCarbonBlackCloud.psm1
```
