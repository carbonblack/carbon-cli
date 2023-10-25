using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet is created to add ioc to existing report.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet is created to add ioc to existing report.
.PARAMETER FeedId
Id of the FeedId
.PARAMETER ReportId
Id of the ReportId
.PARAMETER Report
CbcReport under which the ioc should be added.
.PARAMETER Body
Hashtable with information about the IOC
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.OUTPUTS
CbcIoc
.NOTES
Permissions needed: CREATE org.feeds
.EXAMPLE
PS > $Body = @{"MatchType" = "equality"
>    "Field" =  "process_sha256"
>    "Values" = @("SHA256HashOfAProcess")
> }
PS > New-CbcIoc -FeedId JuXVurDTFmszw93it0Gvw -ReportId 59ac2095-c663-44cd-99cb-4ce83e7aa894 -Body $Body

If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > New-CbcIoc -FeedId JuXVurDTFmszw93it0Gvw -ReportId 59ac2095-c663-44cd-99cb-4ce83e7aa894 -Body $Body -Server $SpecifiedServer

.EXAMPLE
PS > $Feed = Get-CbcFeed -Id JuXVurDTFmszw93it0Gvw
PS > New-CbcIoc -Feed $Feed -ReportId 59ac2095-c663-44cd-99cb-4ce83e7aa894 -MatchType equality -Field process_sha256 -Values @("SHA256HashOfAProcess")

.EXAMPLE
PS > $Report = Get-CbcReport -FeedId JuXVurDTFmszw93it0Gvw -ReportId 59ac2095-c663-44cd-99cb-4ce83e7aa894
PS > New-CbcIoc -Report $Report -Body $Body
#>

function New-CbcIoc {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcIoc[]])]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$FeedId,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$ReportId,

        [Parameter(ParameterSetName = "Report", Mandatory = $true)]
        [CbcReport[]]$Report,

        [Parameter(ParameterSetName = "Report", Mandatory = $true)]
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [hashtable]$Body,

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
                        $IOC = @{}
                        $IOC = $Body
                        if (!$IOC.ContainsKey("id")) {
                            $IOC.id = [string](New-Guid)
                        }

                        $UpdatedReport.iocs_v2 = @()
                        if ($Report.IocsV2) {
                            $UpdatedReport.iocs_v2 += $Report.IocsV2
                            $UpdatedReport.iocs_v2 += $IOC
                           
                        }
                        else {
                            $UpdatedReport.iocs_v2 += $IOC
                        }

                        $RequestBody = $UpdatedReport        
                        $RequestBody = $RequestBody | ConvertTo-Json -Depth 100
        
                        $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                            -Method PUT `
                            -Server $_ `
                            -Params @($FeedId, $ReportId) `
                            -Body $RequestBody
        
                        if ($Response.StatusCode -ne 200) {
                            Write-Error -Message $("Cannot update reports for $($_)")
                        }
                        else {
                            return Initialize-CbcIoc $IOC $FeedId $ReportId $CurrentServer
                        }
                    }
                }
            }
            "Report" {
                $Report | ForEach-Object {
                    $CurrentReport = $_
                    if ($CurrentReport.IocsV2.Count -ge 10000) {
                        Write-Error "Cannot add more IOCs to this report."
                    }
                    else {
                        $RequestBody = @{}
                        $UpdatedReport = @{}
                        $UpdatedReport.title = $CurrentReport.Title
                        $UpdatedReport.description = $CurrentReport.Description
                        $UpdatedReport.severity = $CurrentReport.Severity
                        $UpdatedReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                        $UpdatedReport.id = $CurrentReport.Id
                        $IOC = $Body
                        if (!$IOC.ContainsKey("id")) {
                            $IOC.id = [string](New-Guid)
                        }

                        $UpdatedReport.iocs_v2 = @()
                        if ($CurrentReport.IocsV2) {
                            $UpdatedReport.iocs_v2 = $CurrentReport.IocsV2 + $IOC
                        }
                        else {
                            $UpdatedReport.iocs_v2 = @($IOC)
                        }

                        $RequestBody = $UpdatedReport        
                        $RequestBody = $RequestBody | ConvertTo-Json -Depth 100
        
                        $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                            -Method PUT `
                            -Server $CurrentReport.Server `
                            -Params @($CurrentReport.FeedId, $CurrentReport.Id) `
                            -Body $RequestBody
        
                        if ($Response.StatusCode -ne 200) {
                            Write-Error -Message $("Cannot update reports for $($CurrentReport.Server)")
                        }
                        else {
                            return Initialize-CbcIoc $IOC $CurrentReport.FeedId $CurrentReport.Id $CurrentReport.Server
                        }
                    }
                }
            }
        }
    }
}