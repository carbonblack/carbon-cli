@{
    "Devices" = @{
        "Search"             = "appservices/v6/orgs/{0}/devices/_search"
        "Details"            = "appservices/v6/orgs/{0}/devices/{1}"
        "ExportDevicesCSV"   = "appservices/v6/orgs/{0}/devices/_search/download"
        "Actions"            = "appservices/v6/orgs/{0}/device_actions"
    }
    "Policies"  = @{
        "Search" = "policyservice/v1/orgs/{0}/policies/summary"
        "Details" = "policyservice/v1/orgs/{0}/policies/{1}"
    }
    "Alerts" = @{
        "Search" = "appservices/v6/orgs/{0}/alerts/_search"
        "Details" = "appservices/v6/orgs/{0}/alerts/{1}"
        "Dismiss" = "appservices/v6/orgs/{0}/alerts/workflow/_criteria"
    }
}
