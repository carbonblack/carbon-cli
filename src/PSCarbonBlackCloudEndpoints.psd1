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
    "Observations" = @{
        "StartJob" = "api/investigate/v2/orgs/{0}/observations/search_jobs"
        "Results" = "api/investigate/v2/orgs/{0}/observations/search_jobs/{1}/results{2}"
    }
    "ObservationDetails" = @{
        "StartJob" = "api/investigate/v2/orgs/{0}/observations/detail_jobs"
        "Results" = "api/investigate/v2/orgs/{0}/observations/detail_jobs/{1}/results{2}"
    }
    "Processes" = @{
        "StartJob" = "api/investigate/v2/orgs/{0}/processes/search_jobs"
        "Results" = "api/investigate/v2/orgs/{0}/processes/search_jobs/{1}/results{2}"
    }
    "ProcessDetails" = @{
        "StartJob" = "api/investigate/v2/orgs/{0}/processes/detail_jobs"
        "Results" = "api/investigate/v2/orgs/{0}/processes/detail_jobs/{1}/results{2}"
    }
}
