using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet is created to add ioc to existing report.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet is created to add ioc to existing report.
.PARAMETER FeedId
Id of the FeedId (required)
.PARAMETER Feed
CbcFeed object
.PARAMETER ReportId
Id of the ReportId (required)
.PARAMETER Report
CbcReport - contains the FeedId and ReportId - can be provided instead of FeedId & ReportId
.PARAMETER Body
Hashtable with information about the IOC - either this or the MatchType, IOCValues and Field should be provided.
.PARAMETER MatchType
MatchType of the IOC (required) - possible values: equality, regex, query
.PARAMETER IOCValues
Values for the IOC (required)
.PARAMETER Field
Search field to match on (optional)
.OUTPUTS
CbcIoc
.NOTES
Permissions needed: CREATE org.feeds
.EXAMPLE
PS > New-CbcIoc -FeedId JuXVurDTFmszw93it0Gvw -Id 59ac2095-c663-44cd-99cb-4ce83e7aa894 -MatchType equality -Field process_sha256 -Values @("SHA256HashOfAProcess")

If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > New-CbcIoc -FeedId JuXVurDTFmszw93it0Gvw -Id 59ac2095-c663-44cd-99cb-4ce83e7aa894 -MatchType equality -Field process_sha256 -Values @("SHA256HashOfAProcess") -Server $SpecifiedServer

.EXAMPLE
PS > $Feed = Get-CbcFeed -Id JuXVurDTFmszw93it0Gvw
PS > New-CbcIoc -Feed $Feed -Id 59ac2095-c663-44cd-99cb-4ce83e7aa894 -MatchType equality -Field process_sha256 -Values @("SHA256HashOfAProcess")

.EXAMPLE
PS > $Feed = Get-CbcFeed -Id JuXVurDTFmszw93it0Gvw
PS > $Body = @{"MatchType" = "equality"
>    "Field" =  "process_sha256"
>    "Values" = @("SHA256HashOfAProcess")
> }
PS > New-CbcIoc -Feed $Feed -Id 59ac2095-c663-44cd-99cb-4ce83e7aa894 -Body $Body

.EXAMPLE
PS > $Report = Get-CbcReport -FeedId JuXVurDTFmszw93it0Gvw -Id 59ac2095-c663-44cd-99cb-4ce83e7aa894
PS > New-CbcIoc -Report $Report -MatchType equality -Field process_sha256 -Values @("SHA256HashOfAProcess")
#>

function New-CbcIoc {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcIoc])]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [Parameter(ParameterSetName = "CustomBody")]
        [string]$FeedId,

        [Parameter(ParameterSetName = "Feed", Mandatory = $true)]
        [Parameter(ParameterSetName = "CustomBody")]
        [CbcFeed]$Feed,

        [Parameter(ParameterSetName = "Feed", Mandatory = $true)]
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [Parameter(ParameterSetName = "CustomBody")]
        [string]$ReportId,

        [Parameter(ParameterSetName = "Report", Mandatory = $true)]
        [Parameter(ParameterSetName = "CustomBody")]
        [CbcReport]$Report,

        [Parameter(ParameterSetName = "Feed")]
        [Parameter(ParameterSetName = "Report")]
        [Parameter(ParameterSetName = "CustomBody", Mandatory = $true)]
        [hashtable]$Body,

        [Parameter(ParameterSetName = "Feed")]
        [Parameter(ParameterSetName = "Report")]
        [Parameter(ParameterSetName = "Default")]
        [string]$MatchType,

        [Parameter(ParameterSetName = "Feed")]
        [Parameter(ParameterSetName = "Report")]
        [Parameter(ParameterSetName = "Default")]
        [string[]]$Values,

        [Parameter(ParameterSetName = "Feed")]
        [Parameter(ParameterSetName = "Report")]
        [Parameter(ParameterSetName = "Default")]
        [string]$Field,

        [Parameter(ParameterSetName = "CustomBody")]
        [Parameter(ParameterSetName = "Default")]
        [CbcServer[]]$Server
    )

    process {
        if ($Server) {
            $ExecuteServers = $Server
        }
        else {
            $ExecuteServers = $global:DefaultCbcServers
        }
        Write-Host $PSCmdlet.ParameterSetName
        if ($PSBoundParameters.ContainsKey("FeedId") -and $PSBoundParameters.ContainsKey("ReportId")) {
            $ExecuteServers | ForEach-Object {
                $CurrentServer = $_
                $Report = Get-CbcReport -FeedId $FeedId -Id $ReportId -Server $_
                if ($Report.IocsV2.Count -ge 10000) {
                    Write-Error "Cannot add more IOCs to this report."
                }
                else {
                    $RequestBody = @{}
                    $UpdatedReport = @{}
                    $UpdatedReport.title = $Report.Title
                    $UpdatedReport.description = $Report.Description
                    $UpdatedReport.severity = $Report.Severity
                    $UpdatedReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                    $UpdatedReport.id = $Report.Id
                    if ($PSBoundParameters.ContainsKey("Body")) {
                        if (!$Body.ContainsKey("id")) {
                            $Body.id = [string](New-Guid)
                        }
                        $IOC = $Body
                    }
                    else {
                        $IOC = @{
                            "id"         = [string](New-Guid)
                            "match_type" = $MatchType
                            "field"      = $Field
                            "values"     = $Values
                        }
                    }
                    $UpdatedReport.iocs_v2 = @()
                    if ($Report.IocsV2) {
                        $UpdatedReport.iocs_v2 = $Report.IocsV2 + $IOC
                    }
                    else {
                        $UpdatedReport.iocs_v2 = @($IOC)
                    }

                    $RequestBody = $UpdatedReport        
                    $RequestBody = $RequestBody | ConvertTo-Json -Depth 100
    
                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                        -Method PUT `
                        -Server $_ `
                        -Params @($FeedId, $Id) `
                        -Body $RequestBody
    
                    if ($Response.StatusCode -ne 200) {
                        Write-Error -Message $("Cannot update reports for $($_)")
                    }
                    else {
                        return Initialize-CbcIoc $IOC $CurrentServer
                    }
                }
            }
        }
        elseif ($PSBoundParameters.ContainsKey("Feed")) {
            $Report = Get-CbcReport -Feed $Feed -Id $ReportId -Server $Feed.Server
            if ($Report.IocsV2.Count -ge 10000) {
                Write-Error "Cannot add more IOCs to this report."
            }
            else {
                $RequestBody = @{}
                $UpdatedReport = @{}
                $UpdatedReport.title = $Report.Title
                $UpdatedReport.description = $Report.Description
                $UpdatedReport.severity = $Report.Severity
                $UpdatedReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                $UpdatedReport.id = $Report.Id
                $UpdatedReport.iocs_v2 = @()
                if ($PSBoundParameters.ContainsKey("Body")) {
                    if (!$Body.ContainsKey("id")) {
                        $Body.id = [string](New-Guid)
                    }
                    $IOC = $Body
                }
                else {
                    $IOC = @{
                        "id"         = [string](New-Guid)
                        "match_type" = $MatchType
                        "field"      = $Field
                        "values"     = $Values
                    }
                }
                if ($Report.IocsV2) {
                    $UpdatedReport.iocs_v2 = $Report.IocsV2 + $IOC
                }
                else {
                    $UpdatedReport.iocs_v2 = @($IOC)
                }
                $RequestBody = $UpdatedReport

                $RequestBody = $RequestBody | ConvertTo-Json -Depth 100

                $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                    -Method PUT `
                    -Server $Feed.Server `
                    -Params @($Feed.Id, $Id) `
                    -Body $RequestBody

                if ($Response.StatusCode -ne 200) {
                    Write-Error -Message $("Cannot update reports for $($Feed.Server)")
                }
                else {
                    # what to return here?
                    return Initialize-CbcIoc $IOC $CurrentServer
                }
            }
        }
        elseif ($PSBoundParameters.ContainsKey("Report")) {
            if ($Report.IocsV2.Count -ge 10000) {
                Write-Error "Cannot add more IOCs to this report."
            }
            else {
                $RequestBody = @{}
                $UpdatedReport = @{}
                $UpdatedReport.title = $Report.Title
                $UpdatedReport.description = $Report.Description
                $UpdatedReport.severity = $Report.Severity
                $UpdatedReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                $UpdatedReport.id = $Report.Id
                $UpdatedReport.iocs_v2 = @()
                if ($PSBoundParameters.ContainsKey("Body")) {
                    if (!$Body.ContainsKey("id")) {
                        $Body.id = [string](New-Guid)
                    }
                    $IOC = $Body
                }
                else {
                    $IOC = @{
                        "id"         = [string](New-Guid)
                        "match_type" = $MatchType
                        "field"      = $Field
                        "values"     = $Values
                    }
                }
                if ($Report.IocsV2) {
                    $UpdatedReport.iocs_v2 = $Report.IocsV2 + $IOC
                }
                else {
                    $UpdatedReport.iocs_v2 = @($IOC)
                }
                $RequestBody = $UpdatedReport

                $RequestBody = $RequestBody | ConvertTo-Json -Depth 100

                $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                    -Method PUT `
                    -Server $Report.Server `
                    -Params @($Report.FeedId, $Id) `
                    -Body $RequestBody

                if ($Response.StatusCode -ne 200) {
                    Write-Error -Message $("Cannot update reports for $($Report.Server)")
                }
                else {
                    return Initialize-CbcIoc $IOC $CurrentServer
                }
            }
        }
    }
}