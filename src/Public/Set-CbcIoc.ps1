using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet updates existing ioc from all valid connections - the properties that could be updated are match type, field and values.
.LINK  
API Documentation: https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet updates existing ioc from all valid connections - the properties that could be updated are match type, field and values.

An indicator of compromise (IOC) is a query, list of strings, or list of regular expressions which constitutes
actionable threat intelligence that the Carbon Black Cloud is set up to watch for. Any activity that matches one of these may
indicate a compromise of an endpoint.
.PARAMETER FeedId
Specify the FeedId to which the ioc belongs.
.PARAMETER ReportId
Specify the ReportId to which the ioc belongs.
.PARAMETER Id
Specify the Id of the ioc to update.
.PARAMETER Ioc
Specify the CbcIoc to update - as the object contains the FeedId and ReportId the object is enough to identify uniquely the ioc. 
.PARAMETER MatchType
Specify the new match type for the ioc.
.PARAMETER Field
Specify the new field for the ioc.
.PARAMETER Values
Specify the new values for the ioc.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.NOTES
Permissions needed: org.feeds CREATE, UPDATE
.EXAMPLE
PS > Set-CbcIoc -FeedId R4cMgFIhRaakgk749MRr6Q -ReportId 59ac2095-c663-44cd-99cb-4ce83e7aa894 -Id 59ac2095-c663-44cd-99cb-4ce83e7aa811 -MatchType equality

Updates ioc's match type for specific ioc's ids from all connections. 
If you have multiple connections and you want ioc from a specific connection
you can add the `-Server` param.

PS > Set-CbcIoc -FeedId R4cMgFIhRaakgk749MRr6Q -ReportId 59ac2095-c663-44cd-99cb-4ce83e7aa894 -Id 59ac2095-c663-44cd-99cb-4ce83e7aa811 -MatchType equality -Server $SpecifiedServer
.EXAMPLE
PS > $ioc = Get-CbcIoc -Id R4cMgFIhRaakgk749MRr6Q
PS > Set-CbcIoc -Ioc $ioc -MatchType equality -Field process_sha256 -Values "68e656b251e67e8358bef8483ab0d5", "68e656b251e67e8358bef8483ab0d6"

Updates specific ioc details by proving CbcIoc.
#>

function Set-CbcIoc {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$FeedId,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$ReportId,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Ioc", Mandatory = $true)]
        [CbcIoc[]]$Ioc,

        [Parameter(ParameterSetName = "Ioc")]
        [Parameter(ParameterSetName = "Default")]
        [string]$MatchType,

        [Parameter(ParameterSetName = "Ioc")]
        [Parameter(ParameterSetName = "Default")]
        [string]$Field,

        [Parameter(ParameterSetName = "Ioc")]
        [Parameter(ParameterSetName = "Default")]
        [string[]]$Values,

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

        if (!($PSBoundParameters.ContainsKey("MatchType") -or $PSBoundParameters.ContainsKey("Field") -or $PSBoundParameters.ContainsKey("Value"))) {
            Write-Warning "Nothing to update."
        }
        else {
            switch ($PSCmdlet.ParameterSetName) {
                "Default" {
                    $ExecuteServers | ForEach-Object {
                        $Report = Get-CbcReport -FeedId $FeedId -Id $ReportId -Server $_
                        $CurrentServer = $_
                        $UpdatedIocs = @()
                        $RequestBody = @{}
                        $UpdatedReport = @{}
                        $UpdatedReport.title = $Report.Title
                        $UpdatedReport.description = $Report.Description
                        $UpdatedReport.severity = $Report.Severity
                        $UpdatedReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                        $UpdatedReport.id = $Report.Id
                        $UpdatedReport.iocs_v2 = @()

                        $Report.IocsV2 | ForEach-Object {
                            if (!$Id.Contains($_.id)) {
                                $UpdatedReport.iocs_v2 += $_
                            }
                            else {
                                $CurrentIoc = $_
                                if ($PSBoundParameters.ContainsKey("MatchType")) {
                                    $CurrentIoc.match_type = $MatchType
                                }
                                if ($PSBoundParameters.ContainsKey("Field")) {
                                    $CurrentIoc.field = $Field
                                }
                                if ($PSBoundParameters.ContainsKey("Values")) {
                                    $CurrentIoc.values = $Values
                                }
                                $UpdatedReport.iocs_v2 += $CurrentIoc
                                $UpdatedIocs += $CurrentIoc
                            }
                            
                            $RequestBody = $UpdatedReport        
                            $RequestBody = $RequestBody | ConvertTo-Json -Depth 100
            
                            $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                                -Method PUT `
                                -Server $CurrentServer `
                                -Params @($FeedId, $ReportId) `
                                -Body $RequestBody
            
                            if ($Response.StatusCode -ne 200) {
                                Write-Error -Message $("Cannot update iocs for $($_)")
                            }
                            else {
                                Write-Debug -Message $("Ioc(s) successfully updated.")
                                $UpdatedIocs | ForEach-Object {
                                    return Initialize-CbcIoc $_ $FeedId $ReportId $CurrentServer
                                }
                            }
                        }
                    }
                }
                "Ioc" {
                    $IocGroups = $Ioc | Group-Object -Property Server, ReportId
                    foreach ($Group in $IocGroups) {
                        $IocsToUpdate = @()
                        foreach ($CurrIoc in $Group.Group) {
                            $IocsToUpdate += $CurrIoc.Id
                            $CurrentServer = $CurrIoc.Server
                            $CurrentReportId = $CurrIoc.ReportId
                            $CurrentFeedId = $CurrIoc.FeedId
                        }
                        $RequestBody = @{}
                        $Report = Get-CbcReport -FeedId $CurrentFeedId -Id $CurrentReportId -Server $CurrentServer
                        $UpdatedReport = @{}
                        $UpdatedReport.title = $Report.Title
                        $UpdatedReport.description = $Report.Description
                        $UpdatedReport.severity = $Report.Severity
                        $UpdatedReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                        $UpdatedReport.id = $Report.Id
                        $UpdatedReport.iocs_v2 = @()
                        $UpdatedIocs = @()
                        
                        $Report.IocsV2 | ForEach-Object {
                            if (!$IocsToUpdate.Contains($_.id)) {
                                $UpdatedReport.iocs_v2 += $_
                            }
                            else {
                                $CurrentIoc = $_
                                if ($PSBoundParameters.ContainsKey("MatchType")) {
                                    $CurrentIoc.match_type = $MatchType
                                }
                                if ($PSBoundParameters.ContainsKey("Field")) {
                                    $CurrentIoc.field = $Field
                                }
                                if ($PSBoundParameters.ContainsKey("Values")) {
                                    $CurrentIoc.values = $Values
                                }
                                $UpdatedReport.iocs_v2 += $CurrentIoc
                                $UpdatedIocs += $CurrentIoc
                            }
                        }
                        $RequestBody = $UpdatedReport        
                        $RequestBody = $RequestBody | ConvertTo-Json -Depth 100
        
                        $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                            -Method PUT `
                            -Server $CurrentServer `
                            -Params @($CurrentFeedId, $CurrentReportId) `
                            -Body $RequestBody
        
                        if ($Response.StatusCode -ne 200) {
                            Write-Error -Message $("Cannot update iocs for $($CurrentServer)")
                        }
                        else {
                            Write-Debug -Message $("Ioc(s) successfully updated.")
                            $UpdatedIocs | ForEach-Object {
                                return Initialize-CbcIoc $_ $CurrentFeedId $CurrentReportId $CurrentServer
                            }
                        }
                    }
                }
            }
        }
    }
}