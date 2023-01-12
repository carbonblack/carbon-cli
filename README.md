# PSCarbonBlackCloud

A set of powershell cmdlets to interract with Carbon Black Cloud.

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

## Importing the Module

```console
PS> Import-Module ./src/PSCarbonBlackCloud.psm1
```
