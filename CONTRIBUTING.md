# Contributing to PSCarbonBlackCloud
This repository contains a set of Powershell cmdlets, packaged as PSCarbonBlackCloud.psd1 module, for managing Carbon Black Cloud environments and resources. 

# Cmdlet development guidelines 

## General guidelines 
Please familiarize yourself with general Powershell cmdlet development principles and guidelines
- [Cmdlet Development Guidelines](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines?view=powershell-7.3)
## PSCarbonBlackCloud cmdlet development guidelines
### Documentation and examples
- *Each cmdlet should be well documented, taking advantage of the corresponding documentation fields such as `Description` , `Synopses`, `Output` , `Parameter`, `Example`.*
- *Describe each parameter*
- *Provide meaningful examples following real use case scenarios as close as possible*
- *Follow style, patterns and wording from already existing cmdlets, so consistency can be preserved as much as possible.*
### Testing
- Each cmdlet should be covered by corresponding Pester tets, under `src/Tests/Public/Cmdlet-Name.Tests.ps1`
- Make sure each cmdlet ParameterSet and corresponding parameters are covered
- Make sure you cover with tests cmdlet design contracts such as naming, parameter position, pipeline input, etc. 

### `Get-*` cmdlets
- **Semantics:** 
    - *Get cmdlets are used to retrieve Carbon Black Cloud resources from the corresponding list of established connections. Hence Get cmdlets need to be implemented in a way that they retrieve and aggregate results from all connections. See `Connect-CbcServer` help for more details on working with multiple connections.*
-  **Naming:** *PSCarbonBlackCloud Get cmdlets follow the naming convention: `Get-Cbc*`* (Get-CbcPolicy, Get-CbcAlert, Get-CbcProcess, etc.)
-  **Return types:** 
    - *Each get cmdlet should return a strongly typed result, representing the Carbon Black Cloud resources that are retrieved.*
    - *The result from the `Get-Cbc*` cmdlet should be an array of objects of the corresponding type.*
    - *The type should be defined as a class in* **./src/PSCarbonBlackCloud.Classes.psm1 file.** *For example: `Get-CBCAlert` cmdlet returns an array of CbcAlert objects -->* `[OutputType([CbcAlert[]])]`
    - *Each type should contain `[String] Id` and `[CbcServer] Server`properties as a minimum*
    - **NB:** *Please refrain from returning `object`, `PSObject` and `PSCustomObject` as this decrease the usability of the cmdlet and makes it hard if not impossible for the consumer to anticipate what properties will be found on the object returned.*
- **Parameters:**  No mandatory parameters. `Get-Cbc*` cmdlets should work just fine without providing any parameters, retrieving all corresponding resources from all established connections.
   - `Id:` Each Get cmdlet should support retrieving the corresponding object by Id. There is no uniqueness guarantee across established connections ( server / organization pairs), hence cmdlet should be implemented in such way that it searches for the object with provided Id across all connections. `Id` parameter should be defined as positional, with position 0 (`[Parameter(Position = 0)]`)
   - `Server:` Each Get cmdlet should support filtering by Server parameter; If provided, the retrieval is executed in the context of each of the provided Server objects. If not, the retrieval is done in the context of each of the active servers/connections ( stored in `$global:DefaultCbcServers`). 
- **ParameterSets:** 
    - If the Get cmdlet requires multiple parametersets ( examples Get-CbcAlert, Get-CbcObservation, etc), the default parameter set should be called `Default` and in general try to stay consistent with the naming of the parameter sets for the already existing cmdlets ( `Id`, `IncludeExclude`, etc)
### `Set-*` cmdlets
- **Semantics:** 
    - *Set cmdlets are used to manipulate and change the state of Carbon Black Cloud resources on the server.*
    - *Common flow: Get-Cbc* -SomeFilterParam $filter | Set-Cbc* -SomeProperty $changeState*
    - *See help for `Set-CbcDevice` for concrete examples* 
-  **Naming:** *PSCarbonBlackCloud Set cmdlets follow the naming convention: `Set-Cbc*`* (Set-CbcDevice, Set-CbcAlert, etc.)
-  **Return types:** 
    - *Each set cmdlet should return the modified object/s. In some cases, depending on the API being used for implementation, that might require two API calls: 1 PUT/PATCH/POST and 1 GET call. For reference see: `Set-CbcAlert` implementation.*
    - *Successful execution of the cmdlet is an indication that the corresponding resource is updated on the server.*
- **Parameters:**  *In general Set cmdlets should support accepting both the Id of the object and the Object itself as identifiers of the resource to be updated.* 
   - `Id:` *Each Set cmdlet should support accepting the Id of the object to be updated. For example Set-CbcDevice should accept String[] object as an argument of the Id parameter. As there is no Id uniqueness guarantee across established connections ( server / organization pairs), the cmdlet should be implemented in such way that it updates all resources with corresponding Ids from all connections either specified as arguments of the Server parameter or all active servers/connections ( stored in `$global:DefaultCbcServers`), if Server param is not specified. Id parameter **should be defined in its own parameterset named `Id`, should be mandatory (in that parameterset) and should accept pipeline input**.*
   - `ObjectToBeUpdated:` *Each Set cmdlet should support accepting the object (so to say) to be updated. For example Set-CbcDevice should accept CbcDevice[] object as an argument of the Device parameter. This object parameter should be defined in its own parameterset (so Id and the object can't be specified in the same cmdlet invocation). If the used API supports identifying the resource to be updated only by Id, then the cmdlet implementation should extract both the Id and the connection context (Server/Organization ) from the corresponding Object argument. The corresponding Object parameter should be mandatory in this parameterset and should accept pipeline input.*
   - `Server:` *Each Set cmdlet should support Server parameter in the `id` parameterset and should NOT support it in the corresponding object parameterset.*
- **ParameterSets:** 
    - As described in the **Parameters** section, each Set-Cbc* cmdlet should have at least two parameterSets: Id and the corresponding object parameterset.
### `New-*` cmdlets
- TODO. Corresponding guidelines will be documented alongside the introduction of the first New-Cbc* cmdlet
### `Delete-*` cmdlets
- TODO. Corresponding guidelines will be documented alongside the introduction of the first Delete-Cbc* cmdlet