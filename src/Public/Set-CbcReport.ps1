using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet is created to do actions on reports - adds ioc to report.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet is created to do actions on reports - adds ioc to report.
.PARAMETER FeedId
Id of the FeedId
.PARAMETER Feed
CbcFeed object
.PARAMETER Id
Id of the ReportId (required)
.PARAMETER Action
What action to be performed - currently only supports ADDIOC
.PARAMETER MatchType
MatchType of the IOC (required) - possible values: equality, regex, query
.PARAMETER IOCValues
Values for the IOC (required)
.PARAMETER Field
Search field to match on (optional)
.OUTPUTS
CbcReport
.NOTES
Permissions needed: CREATE org.feeds
.EXAMPLE
PS > Set-CbcReport -FeedId JuXVurDTFmszw93it0Gvw -Id 59ac2095-c663-44cd-99cb-4ce83e7aa894 -Action ADDIOC -MatchType equality -Field process_sha256 -Values "SHA256HashOfAProcess"

If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > Set-CbcReport -FeedId JuXVurDTFmszw93it0Gvw -Id 59ac2095-c663-44cd-99cb-4ce83e7aa894 -Action ADDIOC -MatchType equality -Field process_sha256 -Values "SHA256HashOfAProcess" -Server $SpecifiedServer

.EXAMPLE
PS > $Feed = Get-CbcFeed -Id JuXVurDTFmszw93it0Gvw
PS > Set-CbcReport -Feed $Feed -Id 59ac2095-c663-44cd-99cb-4ce83e7aa894 -Action ADDIOC -MatchType equality -Field process_sha256 -Values "SHA256HashOfAProcess"
#>

function Set-CbcReport {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcReport])]
    param(
        [Parameter(ParameterSetName = "Default", Position = 0, Mandatory = $true)]
        [string]$FeedId,

        [Parameter(ParameterSetName = "Feed", Position = 0, Mandatory = $true)]
        [CbcFeed]$Feed,

        [Parameter(ParameterSetName = "Feed", Mandatory = $true)]
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$Id,

        [Parameter(ParameterSetName = "Feed", Mandatory = $true)]
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$Action,

        [Parameter(ParameterSetName = "Feed", Mandatory = $true)]
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [Parameter(ParameterSetName = "AddIOC", Mandatory = $true)]
        [string]$MatchType,

        [Parameter(ParameterSetName = "Feed", Mandatory = $true)]
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [Parameter(ParameterSetName = "AddIOC", Mandatory = $true)]
        [string[]]$Values,

        [Parameter(ParameterSetName = "Feed", Mandatory = $true)]
        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "AddIOC")]
        [string]$Field,

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

        switch ($PSCmdlet.ParameterSetName) {
            "Default" {
                $ExecuteServers | ForEach-Object {
                    $CurrentServer = $_
                    $Report = Get-CbcReport -FeedId $FeedId -Id $Id
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
                        $IOC = @{
                            "id"         = [string](New-Guid)
                            "match_type" = $MatchType
                            "field"      = $Field
                            "values"     = $Values
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
                            -Server $_ `
                            -Params @($FeedId, $Id) `
                            -Body $RequestBody
        
                        if ($Response.StatusCode -ne 200) {
                            Write-Error -Message $("Cannot update reports for $($_)")
                        }
                        else {
                            $JsonContent = $Response.Content | ConvertFrom-Json
                            return Initialize-CbcReport $JsonContent $CurrentServer
                        }
                    }
                }
            }
            "Feed" {
                $Report = Get-CbcReport -Feed $Feed -Id $Id
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
                    $IOC = @{
                        "id"         = [string](New-Guid)
                        "match_type" = $MatchType
                        "field"      = $Field
                        "values"     = $Values
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
                        $JsonContent = $Response.Content | ConvertFrom-Json
                        return Initialize-CbcReport $JsonContent $Feed.Server
                    }
                }
            }
        }
    }
}